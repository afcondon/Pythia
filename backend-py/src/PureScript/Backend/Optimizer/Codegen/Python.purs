-- | Python codegen over the backend-optimizer's optimized IR ('NeutralExpr').
-- |
-- | This is the optimizer-consumer lane for Pythia (`purepy` is the oracle; see
-- | the family decision in `docs/kb/architecture/adopt-backend-optimizer-family-wide.md`).
-- | It emits ONE PYTHON FILE PER PURESCRIPT MODULE, named and imported exactly as
-- | `purepy` names them, so the *same* `_purepy_runtime.py` and the *same*
-- | `<Module>_foreign.py` shims serve both lanes. That is deliberate: Gnomon's two
-- | forked Go runtimes silently diverged by two symbols and needed a red CI to
-- | find. Here a fork is not possible -- the runtime and the foreigns are produced
-- | by `purepy` and consumed unmodified.
-- |
-- | STATEMENT-ORIENTED, which is the substantive difference from `purepy` and from
-- | the `backend-go` template this was ported from. Python's `lambda` takes an
-- | expression, so an expression-oriented emitter has to encode blocks as
-- | `(lambda: ((x := e), body)[-1])()` -- which is what `purepy` does, and which is
-- | why `purepy` needs lambda-lifting to stay under CPython's ~200-deep paren cap.
-- | Emitting statements sidesteps that entirely: a `Let` is an assignment, a
-- | `Branch` is an `if`/`elif` chain, an `EffectBind` chain is a flat sequence.
-- | Only real lexical nesting costs indentation, and the `elif` flattening below
-- | keeps a wide `case` at one level rather than N.
-- |
-- | Representation is `purepy`'s (it has to be -- the foreigns are shared):
-- | ADTs are tag-tuples `("Just", x)` with the tag at index 0 and field *i* at
-- | *i+1*; records and dictionaries are dicts; arrays are lists; chars are
-- | 1-character strings; `Effect a` is a zero-argument closure; a `Ref` is a
-- | one-element list; functions are curried unary closures.
-- |
-- | DELIBERATE SLICES (each named, none accidental):
-- |
-- |   * Curried `Abs`/`App` as in `backend-go` and `backend-es`: the optimizer's
-- |     `App f args` is a syntactic spine, not a saturation guarantee, so native
-- |     n-ary emission would be unsound. `Uncurried*` (Fn/EffectFn) nodes DO emit
-- |     native multi-arg defs.
-- |   * TCO reuses the shared runtime's `_tco_run` rather than a `while` loop.
-- |     This is not laziness: a Python `for`/`while` body shares one frame, so a
-- |     closure created inside it would capture the LAST iteration's bindings.
-- |     `_tco_run` calls the loop body as a function per iteration, which is
-- |     exactly why `purepy` shaped it that way (and why purs shapes JS TCO that
-- |     way). Self-recursion and MUTUAL recursion both lower to it; mutual adds a
-- |     leading branch register, and needs no runtime change at all.
-- |   * Laziness is applied only where it is needed -- a recursive top-level group
-- |     that is not all-functions -- rather than uniformly as in `backend-go`.
-- |     Python resolves globals late, so a recursive group of functions needs no
-- |     thunking, and keeping plain bindings plain is what lets a shared foreign
-- |     value (`unit = None`) be referenced without forcing.
module PureScript.Backend.Optimizer.Codegen.Python
  ( Env
  , ModuleOutput
  , codegenModule
  , lazyIdentsOf
  , pyModuleName
  , pyModuleAlias
  , pyForeignModuleName
  , pyIdent
  , pyFileName
  , runtimeImport
  ) where

import Prelude

import Control.Alternative (guard)
import Control.Monad.State (State, get, modify_, put, runState)
import Data.Array as Array
import Data.Array.NonEmpty (NonEmptyArray)
import Data.Array.NonEmpty as NEA
import Data.Char (toCharCode)
import Data.Foldable (foldMap, for_, traverse_)
import Data.Int (hexadecimal, toStringAs)
import Data.Map (Map)
import Data.Map as Map
import Data.Maybe (Maybe(..), fromMaybe, maybe)
import Data.Newtype (unwrap)
import Data.Number as Number
import Data.Set (Set)
import Data.Set as Set
import Data.String as String
import Data.String.CodeUnits as SCU
import Data.Traversable (traverse)
import Data.Tuple (Tuple(..), snd)
import PureScript.Backend.Optimizer.Codegen.Tco (LocalRef, TcoAnalysis(..), TcoExpr(..), TcoRef(..), analyze, tcoRoleIsLoop, topLevelTcoEnvGroup, topLevelTcoRefBindings)
import PureScript.Backend.Optimizer.Convert (BackendBindingGroup, BackendModule)
import PureScript.Backend.Optimizer.CoreFn (Ident(..), Literal(..), ModuleName(..), Prop(..), Qualified(..))
import PureScript.Backend.Optimizer.Semantics (NeutralExpr)
import PureScript.Backend.Optimizer.Syntax (BackendAccessor(..), BackendEffect(..), BackendOperator(..), BackendOperator1(..), BackendOperator2(..), BackendOperatorNum(..), BackendOperatorOrd(..), BackendSyntax(..), Level(..), Pair(..))

--------------------------------------------------------------------------------
-- Environment and output
--------------------------------------------------------------------------------

-- | `lazyIdents` is the whole-program set of top-level bindings emitted as
-- | `_runtime_lazy` thunks; a reference to one is forced with a trailing `()`.
-- | It is computed by `lazyIdentsOf` over every module before any is emitted,
-- | because the decision is per-*definition* and the reference can be anywhere.
type Env =
  { currentModule :: ModuleName
  , lazyIdents :: Set (Qualified Ident)
  -- | Enclosing local binders, keyed by their DEFAULT name, mapped to the name
  -- | actually emitted. Non-empty only where a binder shadows one already in
  -- | scope -- see `bindLocal`.
  , locals :: Map String String
  }

type ModuleOutput =
  { lines :: Array String
  -- | Modules actually referenced, so the header imports exactly what is used
  -- | (`BackendModule.imports` is pre-pruning and would name modules that entry
  -- | reachability has since deleted -- importing one is an ImportError).
  , used :: Set ModuleName
  }

-- | The runtime names this codegen emits calls to. All are defined by `purepy`'s
-- | own `_purepy_runtime.py`; nothing here writes a runtime.
runtimeImport :: String
runtimeImport =
  "from _purepy_runtime import _runtime_lazy, _tco_run, _pattern_fail, _len, \\\n"
    <> "    _int32, _int_div, _num_div, _pos_inf, _neg_inf, _nan"

--------------------------------------------------------------------------------
-- The emit monad
--------------------------------------------------------------------------------

type GenState =
  { fresh :: Int
  , out :: Array String
  , used :: Set ModuleName
  -- | Every local name already emitted anywhere in this module. See `bindLocal`.
  , usedLocals :: Set String
  }

type Gen = State GenState

-- | Append one line of output at the current block level. Every string passed
-- | here MUST be a single line: `indent` prefixes whole strings, so an embedded
-- | newline would silently emit an under-indented continuation.
emit :: String -> Gen Unit
emit line = modify_ \st -> st { out = Array.snoc st.out line }

emitAll :: Array String -> Gen Unit
emitAll = traverse_ emit

-- | Run a sub-computation with a fresh statement buffer, returning its
-- | statements separately so the caller can place them inside a block.
capture :: forall a. Gen a -> Gen (Tuple (Array String) a)
capture g = do
  st0 <- get
  put st0 { out = [] }
  a <- g
  st1 <- get
  put st1 { out = st0.out }
  pure (Tuple st1.out a)

freshName :: String -> Gen String
freshName prefix = do
  st <- get
  put st { fresh = st.fresh + 1 }
  pure (prefix <> show st.fresh)

noteModule :: ModuleName -> Gen Unit
noteModule mn = modify_ \st -> st { used = Set.insert mn st.used }

indent :: Array String -> Array String
indent = map ("    " <> _)

--------------------------------------------------------------------------------
-- Module
--------------------------------------------------------------------------------

codegenModule :: Env -> BackendModule -> ModuleOutput
codegenModule env mod =
  let
    Tuple _ st = runState (traverse_ (genGroup env) mod.bindings)
      { fresh: 0, out: [], used: Set.empty, usedLocals: Set.empty }
  in
    { lines: st.out, used: st.used }

--------------------------------------------------------------------------------
-- Binding groups
--------------------------------------------------------------------------------

-- | How one top-level binding group is emitted. Deciding this in one place
-- | matters: `lazyIdentsOf` (which runs first, over every module) and `genGroup`
-- | must agree exactly, or a reference forces something that was never thunked.
data GroupPlan
  = PlanLoop (NonEmptyArray LoopBinding) -- ^ optimizer says isLoop: `_tco_run` dispatch
  | PlanLazy -- ^ recursive, not all functions: `_runtime_lazy` + forced references
  | PlanPlain -- ^ plain assignments in order

type GroupAnalysis =
  { analyzed :: NonEmptyArray (Tuple Ident TcoExpr)
  , plan :: GroupPlan
  }

analyzeGroup :: ModuleName -> BackendBindingGroup Ident NeutralExpr -> Maybe GroupAnalysis
analyzeGroup mn grp = do
  binds <- NEA.fromArray grp.bindings
  let tenv = if grp.recursive then topLevelTcoEnvGroup mn binds else []
  let analyzed = map (\(Tuple i e) -> Tuple i (analyze tenv e)) binds
  let
    plan
      | not grp.recursive = PlanPlain
      | Just members <- topLevelLoopMembers mn analyzed = PlanLoop members
      -- Python looks globals up at call time, so a recursive group of functions
      -- resolves itself with no thunking; anything else in the group can be
      -- referenced before it is assigned, and must be lazy.
      | Array.all (isFunctionShaped <<< snd) (NEA.toArray analyzed) = PlanPlain
      | otherwise = PlanLazy
  pure { analyzed, plan }

topLevelLoopMembers :: ModuleName -> NonEmptyArray (Tuple Ident TcoExpr) -> Maybe (NonEmptyArray LoopBinding)
topLevelLoopMembers mn analyzed = do
  refBindings <- topLevelTcoRefBindings mn analyzed
  guard (tcoRoleIsLoop refBindings)
  traverse loopBindingOf analyzed

isFunctionShaped :: TcoExpr -> Boolean
isFunctionShaped (TcoExpr _ syn) = case syn of
  Abs _ _ -> true
  UncurriedAbs _ _ -> true
  UncurriedEffectAbs _ _ -> true
  -- A constructor builder is a closed value: it captures nothing from the group.
  CtorDef _ _ _ _ -> true
  _ -> false

-- | The whole-program set of bindings that must be forced at their reference
-- | sites. Runs over every module before emission (see `Env.lazyIdents`).
lazyIdentsOf :: BackendModule -> Set (Qualified Ident)
lazyIdentsOf mod = foldMap groupLazy mod.bindings
  where
  groupLazy grp = case analyzeGroup mod.name grp of
    Just { analyzed, plan: PlanLazy } ->
      Set.fromFoldable (map (\(Tuple ident _) -> Qualified (Just mod.name) ident) (NEA.toArray analyzed))
    _ -> Set.empty

genGroup :: Env -> BackendBindingGroup Ident NeutralExpr -> Gen Unit
genGroup env grp = case analyzeGroup env.currentModule grp of
  Nothing -> pure unit
  Just { analyzed, plan } -> case plan of
    PlanLoop members ->
      genLoopGroup env pyIdentOf (TcoTopLevel <<< Qualified (Just env.currentModule)) members
    -- Each binding's statements are confined to their own `_init_` scope and it
    -- is called immediately. That is not ceremony: a local is named from its de
    -- Bruijn LEVEL, which the optimizer makes unique within a scope but not
    -- across sibling top-level bindings, so two bindings that each open a `Let`
    -- at level 0 would both emit `v0` at module scope and the second would
    -- clobber the first -- silently, and only for a closure that read it late.
    -- (`backend-go` never meets this: every top-level binding there is already a
    -- `func(){}`.) A binding whose value needs no statements stays a plain
    -- assignment.
    PlanPlain -> for_ (NEA.toArray analyzed) \(Tuple ident expr) -> do
      let name = pyIdentOf ident
      Tuple stmts e <- capture (genExpr env expr)
      if Array.null stmts then emit (name <> " = " <> e)
      else do
        emit ("def " <> genPrefix <> "init_" <> name <> "():")
        emitAll (indent (stmts <> [ "return " <> e ]))
        emit (name <> " = " <> genPrefix <> "init_" <> name <> "()")
    PlanLazy -> for_ (NEA.toArray analyzed) \(Tuple ident expr) -> do
      let name = pyIdentOf ident
      Tuple stmts e <- capture (genExpr env expr)
      emit ("def " <> genPrefix <> "init_" <> name <> "():")
      emitAll (indent (stmts <> [ "return " <> e ]))
      emit (name <> " = _runtime_lazy(" <> pyStr name <> ", " <> pyStr (unwrap env.currentModule) <> ", " <> genPrefix <> "init_" <> name <> ")")
  where
  pyIdentOf = pyIdent

--------------------------------------------------------------------------------
-- Tail-call loops
--------------------------------------------------------------------------------

type LoopBinding =
  { ident :: Ident
  , params :: NonEmptyArray (Tuple (Maybe Ident) Level)
  , body :: TcoExpr
  }

-- | One branch of a dispatch group. `wrapper` is `Just` for an ORIGINAL member of
-- | the recursive group (which is a value the program can reference, so it needs
-- | a curried wrapper) and `Nothing` for a folded-in JOIN POINT (which is only
-- | ever jumped to, so it has no value form at all).
type GroupMember =
  { ref :: TcoRef
  , params :: Array LocalRef
  , body :: TcoExpr
  , wrapper :: Maybe Ident
  }

-- | What counts as a tail call while walking a loop body, and how the dispatch
-- | tuple is laid out.
-- |
-- | `layout` is the register file, and it is keyed by LOCAL rather than by
-- | position: one slot per distinct local bound by any branch. That is what makes
-- | join points work. A join point captures variables from the member it was
-- | defined inside (`TCOMutRec`'s `tco4` has `g y' = f (x + 2) y'` reading `f`'s
-- | parameter `x`), and a jump leaves the frame, so a captured variable has to
-- | travel in a register. Keying by local means `x` gets ONE slot whether it
-- | arrives as `f`'s parameter or as `g`'s captured free variable, and every
-- | branch binds every slot on entry — so at any jump site, every slot is in
-- | scope and can be passed on.
type LoopCtx =
  { members :: Array { ref :: TcoRef, arity :: Int, params :: Array LocalRef }
  , layout :: Array LocalRef
  , argNames :: Array String
  , branching :: Boolean
  }

loopBindingOf :: Tuple Ident TcoExpr -> Maybe LoopBinding
loopBindingOf (Tuple ident (TcoExpr _ (Abs params body))) = Just { ident, params, body }
loopBindingOf _ = Nothing

--------------------------------------------------------------------------------
-- Join points
--------------------------------------------------------------------------------

-- | The free local variables of an expression: every `Local` reference not bound
-- | by an enclosing binder within it.
-- |
-- | Needed only for join points. A join point's body is lifted out of the member
-- | it was written inside and becomes a sibling branch, so anything it captured
-- | from that member has to be passed explicitly.
freeLocals :: TcoExpr -> Set LocalRef
freeLocals (TcoExpr _ syn) = case syn of
  Local mbId lvl -> Set.singleton (Tuple mbId lvl)
  Abs params body -> without (NEA.toArray params) (freeLocals body)
  UncurriedAbs params body -> without params (freeLocals body)
  UncurriedEffectAbs params body -> without params (freeLocals body)
  Let mbId lvl val body -> freeLocals val <> without [ Tuple mbId lvl ] (freeLocals body)
  EffectBind mbId lvl val body -> freeLocals val <> without [ Tuple mbId lvl ] (freeLocals body)
  LetRec lvl bindings body ->
    without (map (\(Tuple ident _) -> Tuple (Just ident) lvl) (NEA.toArray bindings))
      (foldMap (freeLocals <<< snd) (NEA.toArray bindings) <> freeLocals body)
  _ -> foldMap freeLocals syn
  where
  without bs = flip Set.difference (Set.fromFoldable bs)

-- | Does this node's `joins` role name a member of the group being emitted?
-- |
-- | The check matters because `joins` is computed against whatever TCO scope was
-- | in force where the node sits, and loops nest: a `Let` deep inside a nested
-- | loop can be a join point of the OUTER group, and folding it into the inner
-- | one would be wrong.
joinsThisGroup :: Array TcoRef -> TcoAnalysis -> Boolean
joinsThisGroup groupRefs (TcoAnalysis a) = Array.any (flip Array.elem groupRefs) a.role.joins

-- | Collect the join points reachable in TAIL position from a member's body.
-- |
-- | Recurses into a join point's own body, because join points nest: `tco2` has
-- | `f` tail-call `g`, `g` tail-call `h`, and `h` tail-call `f`.
-- |
-- | A nested `LetRec` that is a loop but NOT a join of this group is left alone —
-- | it owns its own trampoline, and its members are not branches of ours.
collectJoins :: Array TcoRef -> TcoExpr -> Array GroupMember
collectJoins groupRefs = go
  where
  go (TcoExpr ann syn) = case syn of
    Let mbId lvl val rest
      | joinsThisGroup groupRefs ann
      , TcoExpr _ (Abs params body) <- val ->
          [ { ref: TcoLocal mbId lvl
            , params: NEA.toArray params
            , body
            , wrapper: Nothing
            }
          ] <> go body <> go rest
      | otherwise -> go rest

    LetRec lvl bindings rest
      | joinsThisGroup groupRefs ann
      , Just ms <- traverse loopBindingOf bindings ->
          Array.concatMap
            ( \m ->
                [ { ref: TcoLocal (Just m.ident) lvl
                  , params: NEA.toArray m.params
                  , body: m.body
                  , wrapper: Nothing
                  }
                ] <> go m.body
            )
            (NEA.toArray ms)
            <> go rest
      | isLoopAnalysis ann -> []
      | otherwise -> go rest

    Branch pairs def -> foldMap (\(Pair _ body) -> go body) (NEA.toArray pairs) <> go def

    _ -> []

-- | Emit a loop group as statements: one `_loop_*` dispatch function plus one
-- | curried wrapper per ORIGINAL member. Used for both top-level groups (`nameOf`
-- | = module-level name, `refOf` = `TcoTopLevel`) and local `LetRec` groups
-- | (`nameOf` = the local name, `refOf` = `TcoLocal`).
-- |
-- | Generalised twice over the plain self-recursive case: a leading branch
-- | register lets several members share one loop (MUTUAL tail recursion), and
-- | join points are folded in as further branches, so a helper written in a
-- | `where` NESTED inside a loop member becomes a jump rather than a call.
genLoopGroup
  :: Env
  -> (Ident -> String)
  -> (Ident -> TcoRef)
  -> NonEmptyArray LoopBinding
  -> Gen Unit
genLoopGroup env nameOf refOf members = do
  let
    origs = map
      ( \m ->
          { ref: refOf m.ident
          , params: NEA.toArray m.params
          , body: m.body
          , wrapper: Just m.ident
          }
      )
      (NEA.toArray members)
  let groupRefs = map _.ref origs
  let joins = Array.concatMap (collectJoins groupRefs <<< _.body) origs
  let allMembers = origs <> joins
  let branching = Array.length allMembers > 1

  -- One slot per distinct local any branch binds: every member's parameters,
  -- plus the free variables the join points captured from the member bodies they
  -- were lifted out of.
  --
  -- The level filter keeps the register file small and, more importantly,
  -- correct. The dispatch `def` is emitted lexically INSIDE the scope that
  -- encloses the group, so anything bound further out is already reachable and
  -- must NOT be shadowed by a register (`tco3`'s `g` reads `y0` and `j` from two
  -- scopes up). Only locals bound at or inside the member bodies have to travel.
  let memberParams = Array.concatMap _.params allMembers
  let threshold = Array.foldl (\acc (Tuple _ (Level n)) -> min acc n) top memberParams
  let joinRefs = map _.ref joins
  let
    captured = Array.filter
      ( \r@(Tuple mbId (Level n)) ->
          n >= threshold
            && not (Array.elem r memberParams)
            && not (Array.elem (TcoLocal mbId (Level n)) groupRefs)
            && not (Array.elem (TcoLocal mbId (Level n)) joinRefs)
      )
      (Set.toUnfoldable (foldMap (freeLocals <<< _.body) joins))
  let layout = Array.nub (memberParams <> captured)

  -- The tag must be unique across the whole MODULE, not merely within a scope:
  -- the dispatch function is a named `def`, and two loop groups whose first
  -- parameter shares a de Bruijn level would otherwise both be `_loop0` and the
  -- second would redefine the first. The fresh counter is module-wide.
  tag <- freshName ""
  let loopName = genPrefix <> "loop" <> tag
  let
    argNames = map (\i -> genPrefix <> "a" <> tag <> "_" <> show i)
      (Array.range 0 (max 1 (Array.length layout) - 1))
  let
    ctx =
      { members: map (\m -> { ref: m.ref, arity: Array.length m.params, params: m.params }) allMembers
      , layout
      , argNames
      , branching
      }
  let branchName = genPrefix <> "br" <> tag

  -- The register file is bound ONCE, and every branch and every wrapper reuses
  -- those names. Binding per branch would be wrong here in a way it is not in the
  -- Julia lane: `bindLocal` enforces module-wide uniqueness, so the second branch
  -- to bind a given slot would be renamed away from the first.
  Tuple envL slotNames <- bindLocals env layout

  bodies <- traverse (memberBlock envL ctx slotNames branchName branching) (Array.mapWithIndex Tuple allMembers)
  emit ("def " <> loopName <> "(" <> commaSep ((if branching then [ branchName ] else []) <> argNames) <> "):")
  emitAll (indent (Array.concat bodies))

  -- One curried wrapper per ORIGINAL member, entering the loop with its branch
  -- index. Join points get none: they are not values, only jump targets.
  for_ (Array.mapWithIndex Tuple allMembers) \(Tuple idx m) -> case m.wrapper of
    Nothing -> pure unit
    Just ident -> do
      let ps = map (\(Tuple mbId lvl) -> localRef envL mbId lvl) m.params
      -- At the wrapper only this member's own parameters are in scope; every
      -- other slot starts empty. Safe because a slot no branch has written is a
      -- join point's captured variable, and no join point has run yet.
      let entry = (if branching then [ show idx ] else []) <> slotArgs envL ctx idx ps m.params
      let call = "_tco_run(" <> loopName <> ", (" <> commaSep entry <> ",))"
      emitAll (nestedDef (nameOf ident) ps [] call)

-- | The full register tuple for a jump to member `idx`: that member's parameters
-- | take their argument expressions, and every other slot carries its local
-- | through unchanged.
-- |
-- | `inScope` names the locals the jump site can actually read. Inside a branch
-- | that is every slot (each branch binds the whole layout on entry), so nothing
-- | is lost; at a wrapper it is only that member's parameters, and the rest start
-- | as `None`.
slotArgs :: Env -> LoopCtx -> Int -> Array String -> Array LocalRef -> Array String
slotArgs env ctx idx args inScope = map slotFor ctx.layout
  where
  targetParams = maybe [] _.params (Array.index ctx.members idx)
  slotFor loc@(Tuple mbId lvl) = case Array.elemIndex loc targetParams of
    Just i -> fromMaybe "None" (Array.index args i)
    Nothing
      | Array.elem loc inScope -> localRef env mbId lvl
      | otherwise -> "None"

-- | One branch inside the dispatch function: bind the WHOLE register file, then
-- | walk the body in tail-aware statement mode.
-- |
-- | Binding every slot rather than only this branch's parameters is deliberate.
-- | It costs a few dead assignments and buys the invariant the join machinery
-- | rests on: every slot is in scope in every branch, so any jump can pass every
-- | slot on, and a captured variable survives an arbitrary chain of jumps.
memberBlock :: Env -> LoopCtx -> Array String -> String -> Boolean -> Tuple Int GroupMember -> Gen (Array String)
memberBlock env ctx slotNames branchName branching (Tuple idx m) = do
  Tuple stmts _ <- capture do
    for_ (Array.mapWithIndex Tuple slotNames) \(Tuple i name) ->
      emit (name <> " = " <> fromMaybe "None" (Array.index ctx.argNames i))
    genLoopStmts env ctx ctx.layout m.body
  pure
    if branching then [ "if " <> branchName <> " == " <> show idx <> ":" ] <> indent stmts
    else stmts

-- | Tail-aware statement walk of a loop body. A tail call to a branch of this
-- | group becomes `return (1, (registers...))` -- the continue signal `_tco_run`
-- | reads -- and every other tail position becomes `return (0, value)`.
-- |
-- | `inScope` grows as the walk passes binders, and is what a jump reads to fill
-- | the slots it is not supplying arguments for.
genLoopStmts :: Env -> LoopCtx -> Array LocalRef -> TcoExpr -> Gen Unit
genLoopStmts env ctx inScope te@(TcoExpr _ syn) = case syn of
  Branch pairs def -> genLoopBranch env ctx inScope (NEA.toArray pairs) def

  -- A join point's binding is NOT emitted: it has become a branch of this
  -- dispatch group, and every reference to it is a jump. The analysis guarantees
  -- there is no other kind of reference -- `joins` requires every use to be a
  -- saturated tail call.
  Let mbId lvl val rest
    | Array.elem (TcoLocal mbId lvl) (map _.ref ctx.members)
    , TcoExpr _ (Abs _ _) <- val -> genLoopStmts env ctx inScope rest
    | otherwise -> do
        v <- genExpr env val
        Tuple env' name <- bindLocal env mbId lvl
        emit (name <> " = " <> v)
        genLoopStmts env' ctx (Array.snoc inScope (Tuple mbId lvl)) rest

  LetRec lvl bindings rest
    | Array.all (\(Tuple ident _) -> Array.elem (TcoLocal (Just ident) lvl) (map _.ref ctx.members))
        (NEA.toArray bindings) -> genLoopStmts env ctx inScope rest

  App (TcoExpr _ hsyn) args
    | Just idx <- findMember ctx hsyn (NEA.length args) -> do
        as <- traverse (genExpr env) (NEA.toArray args)
        let entry = (if ctx.branching then [ show idx ] else []) <> slotArgs env ctx idx as inScope
        emit ("return (1, (" <> commaSep entry <> ",))")

  _ -> do
    e <- genExpr env te
    emit ("return (0, " <> e <> ")")

-- | Every arm of a loop branch ends in a `return`, so the arms can be emitted as
-- | a flat run of `if` statements with the default falling through -- no `else`
-- | nesting, and so no indentation growth with the number of alternatives.
genLoopBranch :: Env -> LoopCtx -> Array LocalRef -> Array (Pair TcoExpr) -> TcoExpr -> Gen Unit
genLoopBranch env ctx inScope pairs def = case Array.uncons pairs of
  Nothing -> genLoopStmts env ctx inScope def
  Just { head: Pair cond body, tail } -> do
    c <- genExpr env cond
    Tuple stmts _ <- capture (genLoopStmts env ctx inScope body)
    emit ("if " <> c <> ":")
    emitAll (indent stmts)
    genLoopBranch env ctx inScope tail def

findMember :: LoopCtx -> BackendSyntax TcoExpr -> Int -> Maybe Int
findMember ctx hsyn nargs =
  Array.findIndex (\m -> m.arity == nargs && matchesRef m.ref hsyn) ctx.members

matchesRef :: TcoRef -> BackendSyntax TcoExpr -> Boolean
matchesRef ref syn = case ref of
  TcoTopLevel q -> case syn of
    Var q2 -> q == q2
    _ -> false
  TcoLocal mbId lvl -> case syn of
    Local mbId2 lvl2 -> mbId == mbId2 && lvl == lvl2
    _ -> false

isLoopAnalysis :: TcoAnalysis -> Boolean
isLoopAnalysis (TcoAnalysis a) = a.role.isLoop

--------------------------------------------------------------------------------
-- Names
--------------------------------------------------------------------------------

-- | @Data.Array@ -> @Data_Array@. Matches `purepy`'s `pyModuleName` -- it has to,
-- | since both lanes import the same generated foreign files.
pyModuleName :: ModuleName -> String
pyModuleName (ModuleName mn) = String.replaceAll (String.Pattern ".") (String.Replacement "_") mn

pyFileName :: ModuleName -> String
pyFileName mn = pyModuleName mn <> ".py"

pyForeignModuleName :: ModuleName -> String
pyForeignModuleName mn = pyModuleName mn <> "_foreign"

-- | The reserved prefix separating the MODULE namespace from the user-value
-- | namespace. Python has one namespace, so a user binding could otherwise
-- | rebind an imported module outright -- `tests/purs/passing/4174` does exactly
-- | that. `pyIdent` escapes any identifier that would land here, making the two
-- | provably disjoint. (Identical to `purepy`'s scheme, and necessarily so.)
moduleAliasPrefix :: String
moduleAliasPrefix = "_psmod_"

-- | The prefix on every name this codegen invents -- locals, temporaries,
-- | lifted `def`s, loop dispatchers, initialisers.
-- |
-- | It exists for the same reason `moduleAliasPrefix` does, and the reasoning is
-- | worth stating because the first version of this file did not have it. A
-- | local named from its de Bruijn level is `v3_x`, and nothing stops a
-- | PureScript module from having a top-level binding *called* `v3_x`: the local
-- | would shadow it, and any reference to the top-level one from inside that
-- | function would silently read the local. `backend-go` is immune because its
-- | top-level names are module-qualified (`Data_Foo_v3_x`); Python's are bare.
-- |
-- | `pyIdent` pushes any user identifier out of this namespace, so the two are
-- | provably disjoint rather than merely unlikely to meet: a generated name is
-- | `_ps_` followed by a letter, an escaped user identifier is `_ps_` followed
-- | by an underscore.
genPrefix :: String
genPrefix = "_ps_"

pyModuleAlias :: ModuleName -> String
pyModuleAlias mn = moduleAliasPrefix <> pyModuleName mn

-- | Mangle a PureScript identifier to a Python one, matching `purepy`'s
-- | `identToPyName` EXACTLY -- the foreign shims are named by it, so any drift
-- | here is an ImportError or, worse, a silent miss.
pyIdent :: Ident -> String
pyIdent (Ident s) =
  let
    name = mangle s
  in
    if isPythonReserved name then name <> "_"
    else escapeReserved moduleAliasPrefix (escapeReserved genPrefix name)

-- | Push an identifier out of a reserved prefix by doubling the separator:
-- | `_ps_x` becomes `_ps__x`, which no generated name can be.
escapeReserved :: String -> String -> String
escapeReserved prefix name =
  if String.take (String.length prefix) name == prefix then
    prefix <> "_" <> String.drop (String.length prefix) name
  else name

mangle :: String -> String
mangle s = case Array.uncons (SCU.toCharArray s) of
  Nothing -> s
  Just { head, tail } -> first head <> foldMap replaceChar tail
  where
  first c
    | isAlpha c || c == '_' = SCU.singleton c
    | otherwise = "_" <> replaceChar c
  replaceChar c = case c of
    '.' -> "_"
    '$' -> "_dollar_"
    '\'' -> "\x2b9" -- MODIFIER LETTER PRIME: category Lm, legal in a Python identifier
    '-' -> "_"
    _ | isValidPythonChar c -> SCU.singleton c
    _ -> "_u" <> hex4 c

isAlpha :: Char -> Boolean
isAlpha c = (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z')

isDigit :: Char -> Boolean
isDigit c = c >= '0' && c <= '9'

isValidPythonChar :: Char -> Boolean
isValidPythonChar c = isAlpha c || isDigit c || c == '_' || c == '\x2b9'

hex4 :: Char -> String
hex4 c =
  let h = toStringAs hexadecimal (toCharCode c)
  in String.drop (String.length h) "0000" <> h

isPythonReserved :: String -> Boolean
isPythonReserved name = Array.elem name
  [ "False", "None", "True"
  , "and", "as", "assert", "async", "await"
  , "break", "class", "continue", "def", "del"
  , "elif", "else", "except", "finally", "for"
  , "from", "global", "if", "import", "in"
  , "is", "lambda", "nonlocal", "not", "or"
  , "pass", "raise", "return", "try", "while"
  , "with", "yield"
  ]

-- | A local binder named from its de Bruijn level (the optimizer guarantees
-- | uniqueness within a scope), with the source name appended for readability.
-- | The `v`-prefix keeps locals out of every other namespace we generate.
localName :: Maybe Ident -> Level -> String
localName mbIdent (Level n) = case mbIdent of
  Just (Ident s) -> genPrefix <> "v" <> show n <> "_" <> foldMap keep (SCU.toCharArray s)
  Nothing -> genPrefix <> "v" <> show n
  where
  keep c = if isAlpha c || isDigit c then SCU.singleton c else ""

-- | Introduce a binder: return the name to emit, and an environment in which
-- | references to it resolve there.
-- |
-- | A local is named from its de Bruijn LEVEL, which the optimizer makes unique
-- | only WITHIN a scope. `backend-go` can take that at face value because its
-- | `Let` is an IIFE, so every IR scope becomes a real target-language scope.
-- | Statement mode has no such thing: sibling IR scopes are flattened into the
-- | one enclosing Python function, and two independent `Let`s that both open at
-- | level 2 would both be assigned to `v2` -- the second silently rebinding the
-- | name a closure over the first had already captured. `Test.Generic` does
-- | exactly this, three times over, in one `Show` instance.
-- |
-- | So uniqueness is enforced against every local name emitted anywhere in the
-- | module, not against the enclosing chain: sibling scopes are precisely the
-- | case the enclosing chain cannot see. This is conservative -- it can rename
-- | where a plain Python scope would already have separated the two -- and
-- | renaming is always safe, since every reference resolves through `Env.locals`
-- | rather than by reconstructing the name.
bindLocal :: Env -> Maybe Ident -> Level -> Gen (Tuple Env String)
bindLocal env mbIdent lvl = do
  st <- get
  let key = localName mbIdent lvl
  name <-
    if Set.member key st.usedLocals then do
      tag <- freshName ""
      pure (key <> "_s" <> tag)
    else pure key
  modify_ \s -> s { usedLocals = Set.insert name s.usedLocals }
  pure (Tuple (env { locals = Map.insert key name env.locals }) name)

bindLocals :: Env -> Array (Tuple (Maybe Ident) Level) -> Gen (Tuple Env (Array String))
bindLocals env0 = Array.foldRecM step (Tuple env0 [])
  where
  step (Tuple env acc) (Tuple mbIdent lvl) = do
    Tuple env' name <- bindLocal env mbIdent lvl
    pure (Tuple env' (Array.snoc acc name))

-- | Resolve a reference to a local binder.
localRef :: Env -> Maybe Ident -> Level -> String
localRef env mbIdent lvl =
  let key = localName mbIdent lvl
  in fromMaybe key (Map.lookup key env.locals)

--------------------------------------------------------------------------------
-- Expressions
--------------------------------------------------------------------------------

genExpr :: Env -> TcoExpr -> Gen String
genExpr env (TcoExpr ann syn) = case syn of
  Var qi -> genRef env qi

  Local mbIdent lvl -> pure (localRef env mbIdent lvl)

  Lit lit -> genLit env lit

  -- Curried spine: `(f)(a)(b)`. Left-associative juxtaposition, so this stays
  -- flat rather than nesting one paren level per argument.
  App f args -> do
    fs <- genExpr env f
    as <- traverse (genExpr env) (NEA.toArray args)
    pure ("(" <> fs <> ")" <> foldMap (\a -> "(" <> a <> ")") as)

  Abs params body -> do
    Tuple env' names <- bindLocals env (NEA.toArray params)
    genAbs env' names body

  UncurriedAbs params body -> do
    Tuple env' names <- bindLocals env params
    Tuple stmts e <- capture (genExpr env' body)
    n <- freshName (genPrefix <> "fn")
    emit ("def " <> n <> "(" <> commaSep names <> "):")
    emitAll (indent (stmts <> [ "return " <> e ]))
    pure n

  -- Calling an uncurried EFFECT function runs its effect, so the body is walked
  -- in effect mode -- inline, rather than built as a thunk and immediately forced.
  UncurriedEffectAbs params body -> do
    Tuple env' names <- bindLocals env params
    Tuple stmts e <- capture (genEffect env' body)
    n <- freshName (genPrefix <> "efn")
    emit ("def " <> n <> "(" <> commaSep names <> "):")
    emitAll (indent (stmts <> [ "return " <> e ]))
    pure n

  UncurriedApp f args -> do
    fs <- genExpr env f
    as <- traverse (genExpr env) args
    pure ("(" <> fs <> ")(" <> commaSep as <> ")")

  -- Yields an `Effect a`, so the call is deferred into a thunk.
  UncurriedEffectApp f args -> thunkOf do
    fs <- genExpr env f
    as <- traverse (genExpr env) args
    pure ("(" <> fs <> ")(" <> commaSep as <> ")")

  Accessor a acc -> do
    b <- genExpr env a
    pure (genAccessor b acc)

  Update base props -> do
    b <- genExpr env base
    ps <- traverse (\(Prop k v) -> (\s -> pyStr k <> ": " <> s) <$> genExpr env v) props
    pure ("{**(" <> b <> ")" <> foldMap (", " <> _) ps <> "}")

  -- Tag-tuple: tag at index 0, fields from index 1.
  CtorSaturated _ _ _ (Ident tag) fields -> do
    fs <- traverse (genExpr env <<< snd) fields
    pure (tupleLit (Array.cons (pyStr tag) fs))

  CtorDef _ _ (Ident tag) fieldNames -> do
    let names = map (\f -> genPrefix <> "f_" <> mangle f) fieldNames
    pure
      if Array.null names then tupleLit [ pyStr tag ]
      else lambdaChain names (tupleLit (Array.cons (pyStr tag) names))

  -- A local recursive group the optimizer marked `isLoop` (the `where go = ...`
  -- idiom, and local mutual recursion).
  LetRec lvl bindings body
    | isLoopAnalysis ann
    , Just members <- traverse loopBindingOf bindings -> do
        Tuple env' _ <- bindLocals env (map (\m -> Tuple (Just m.ident) lvl) (NEA.toArray members))
        genLoopGroup env' (\ident -> localRef env' (Just ident) lvl) (\ident -> TcoLocal (Just ident) lvl) members
        genExpr env' body

  -- Ordinary local recursive group. Python resolves free names at call time, so
  -- emitting the bindings in order is enough for mutual recursion between
  -- functions; all members share the group Level and are told apart by ident.
  LetRec lvl bindings body -> do
    Tuple env' _ <- bindLocals env (map (\(Tuple ident _) -> Tuple (Just ident) lvl) (NEA.toArray bindings))
    for_ (NEA.toArray bindings) \(Tuple ident e) -> do
      v <- genExpr env' e
      emit (localRef env' (Just ident) lvl <> " = " <> v)
    genExpr env' body

  Let mbIdent lvl val body -> do
    v <- genExpr env val
    Tuple env' name <- bindLocal env mbIdent lvl
    emit (name <> " = " <> v)
    genExpr env' body

  -- An `Effect a` VALUE is a thunk; building one means deferring the whole
  -- effect block into a single `def`. `genEffect` is what keeps that block flat.
  EffectBind _ _ _ _ -> thunkOf (genEffect env (TcoExpr ann syn))

  EffectPure _ -> thunkOf (genEffect env (TcoExpr ann syn))

  EffectDefer a -> genExpr env a

  Branch pairs def -> do
    r <- freshName (genPrefix <> "t")
    lines <- branchLines env r (NEA.toArray pairs) def
    emitAll lines
    pure r

  PrimOp op -> genOp env op

  PrimEffect _ -> thunkOf (genEffect env (TcoExpr ann syn))

  PrimUndefined -> pure "None"

  Fail _ -> pure ("_pattern_fail(" <> pyStr (unwrap env.currentModule) <> ")")

-- | A reference to a top-level binding. Bindings in `lazyIdents` are
-- | `_runtime_lazy` thunks and are forced here; everything else -- including
-- | every FOREIGN value, which the shared shims define as a plain value -- is
-- | referenced directly.
genRef :: Env -> Qualified Ident -> Gen String
genRef env (Qualified (Just mn) ident) = do
  let forced = if Set.member (Qualified (Just mn) ident) env.lazyIdents then "()" else ""
  if mn == env.currentModule then pure (pyIdent ident <> forced)
  else do
    noteModule mn
    pure (pyModuleAlias mn <> "." <> pyIdent ident <> forced)
genRef _ (Qualified Nothing ident) = pure (pyIdent ident)

-- | A curried function. Emitted as a parenthesised `lambda` chain when the body
-- | needs no statements (the common case, and far more readable), and as nested
-- | `def`s otherwise.
genAbs :: Env -> Array String -> TcoExpr -> Gen String
genAbs env params body = do
  Tuple stmts e <- capture (genExpr env body)
  if Array.null stmts then pure (lambdaChain params e)
  else do
    n <- freshName (genPrefix <> "fn")
    emitAll (nestedDef n params stmts e)
    pure n

-- | `(lambda a: (lambda b: e))` -- always parenthesised, because a bare lambda
-- | body extends as far right as it can and would swallow a following call.
lambdaChain :: Array String -> String -> String
lambdaChain params e = Array.foldr (\p acc -> "(lambda " <> p <> ": " <> acc <> ")") e params

-- | Nested `def`s realising a curried function whose body needs statements:
-- |
-- | >  def N(a):
-- | >      def N_1(b):
-- | >          <stmts>
-- | >          return <e>
-- | >      return N_1
nestedDef :: String -> Array String -> Array String -> String -> Array String
nestedDef name params stmts retExpr = build 0 params
  where
  nameAt i = if i == 0 then name else name <> "_" <> show i
  build i ps = case Array.uncons ps of
    Nothing -> [ "def " <> nameAt i <> "():" ] <> indent (stmts <> [ "return " <> retExpr ])
    Just { head, tail }
      | Array.null tail ->
          [ "def " <> nameAt i <> "(" <> head <> "):" ] <> indent (stmts <> [ "return " <> retExpr ])
      | otherwise ->
          [ "def " <> nameAt i <> "(" <> head <> "):" ]
            <> indent (build (i + 1) tail <> [ "return " <> nameAt (i + 1) ])

-- | Defer a computation into an `Effect` (a zero-argument closure).
thunkOf :: Gen String -> Gen String
thunkOf g = do
  Tuple stmts e <- capture g
  if Array.null stmts then pure ("(lambda: " <> e <> ")")
  else do
    n <- freshName (genPrefix <> "eff")
    emit ("def " <> n <> "():")
    emitAll (indent (stmts <> [ "return " <> e ]))
    pure n

-- | An `if`/`elif`/`else` chain assigning the branch value to `r`.
-- |
-- | The `elif` flattening is load-bearing, not cosmetic: a `case` with N
-- | alternatives would otherwise nest N `else:` blocks, and CPython caps
-- | indentation at 100 levels. Conditions are almost always pure tag tests,
-- | which need no statements, so the chain stays at one level. A condition that
-- | DOES need statements has to nest -- there is nowhere else to put them.
branchLines :: Env -> String -> Array (Pair TcoExpr) -> TcoExpr -> Gen (Array String)
branchLines env r pairs def = case Array.uncons pairs of
  Nothing -> do
    Tuple stmts e <- capture (genExpr env def)
    pure (stmts <> [ r <> " = " <> e ])
  Just { head: Pair cond body, tail } -> do
    Tuple cstmts c <- capture (genExpr env cond)
    Tuple bstmts b <- capture (genExpr env body)
    rest <- elifChain env r tail def
    pure (cstmts <> [ "if " <> c <> ":" ] <> indent (bstmts <> [ r <> " = " <> b ]) <> rest)

elifChain :: Env -> String -> Array (Pair TcoExpr) -> TcoExpr -> Gen (Array String)
elifChain env r pairs def = case Array.uncons pairs of
  Nothing -> do
    Tuple stmts e <- capture (genExpr env def)
    pure ([ "else:" ] <> indent (stmts <> [ r <> " = " <> e ]))
  Just { head: Pair cond body, tail } -> do
    Tuple cstmts c <- capture (genExpr env cond)
    if Array.null cstmts then do
      Tuple bstmts b <- capture (genExpr env body)
      rest <- elifChain env r tail def
      pure ([ "elif " <> c <> ":" ] <> indent (bstmts <> [ r <> " = " <> b ]) <> rest)
    else do
      inner <- branchLines env r pairs def
      pure ([ "else:" ] <> indent inner)

--------------------------------------------------------------------------------
-- Literals, accessors, operators, effects
--------------------------------------------------------------------------------

genLit :: Env -> Literal TcoExpr -> Gen String
genLit env = case _ of
  LitInt n -> pure (parenNeg (show n))
  LitNumber n
    | Number.isNaN n -> pure "_nan"
    | not (Number.isFinite n) -> pure (if n < 0.0 then "_neg_inf" else "_pos_inf")
    | otherwise -> pure (parenNeg (show n))
  LitString s -> pure (pyStr s)
  LitChar c -> pure (pyStr (SCU.singleton c))
  LitBoolean b -> pure (if b then "True" else "False")
  LitArray as -> do
    xs <- traverse (genExpr env) as
    pure ("[" <> commaSep xs <> "]")
  LitRecord props -> do
    ps <- traverse (\(Prop k v) -> (\s -> pyStr k <> ": " <> s) <$> genExpr env v) props
    pure ("{" <> commaSep ps <> "}")
  where
  parenNeg s = if String.take 1 s == "-" then "(" <> s <> ")" else s

genAccessor :: String -> BackendAccessor -> String
genAccessor base = case _ of
  GetProp k -> "(" <> base <> ")[" <> pyStr k <> "]"
  GetIndex i -> "(" <> base <> ")[" <> show i <> "]"
  -- Field i of a tag-tuple lives at i+1; index 0 is the tag.
  GetCtorField _ _ _ _ _ idx -> "(" <> base <> ")[" <> show (idx + 1) <> "]"

genOp :: Env -> BackendOperator TcoExpr -> Gen String
genOp env = case _ of
  Op1 op a -> genOp1 op <$> genExpr env a

  -- `&&` and `||` MUST short-circuit: the optimizer emits shapes like
  -- `isTag Just x && p (field 0 x)` that depend on the right operand not being
  -- evaluated. When the right operand needs no statements a plain Python
  -- `and`/`or` does it; when it does, the statements have to be guarded, or
  -- they would run unconditionally at the enclosing level.
  Op2 OpBooleanAnd a b -> shortCircuit env true a b
  Op2 OpBooleanOr a b -> shortCircuit env false a b

  Op2 op a b -> genOp2 op <$> genExpr env a <*> genExpr env b

shortCircuit :: Env -> Boolean -> TcoExpr -> TcoExpr -> Gen String
shortCircuit env isAnd a b = do
  a' <- genExpr env a
  Tuple stmts b' <- capture (genExpr env b)
  if Array.null stmts then
    pure ("((" <> a' <> ") " <> (if isAnd then "and" else "or") <> " (" <> b' <> "))")
  else do
    r <- freshName (genPrefix <> "t")
    emit (r <> " = " <> a')
    emit (if isAnd then "if " <> r <> ":" else "if not " <> r <> ":")
    emitAll (indent (stmts <> [ r <> " = " <> b' ]))
    pure r

genOp1 :: BackendOperator1 -> String -> String
genOp1 op a = case op of
  OpBooleanNot -> "(not (" <> a <> "))"
  -- Bit operations follow the shared `Data.Int.Bits` shims exactly: complement
  -- and the shifts wrap to int32, the logical operations do not.
  OpIntBitNot -> "_int32(~(" <> a <> "))"
  OpIntNegate -> "(-(" <> a <> "))"
  OpNumberNegate -> "(-(" <> a <> "))"
  OpArrayLength -> "_len(" <> a <> ")"
  OpIsTag (Qualified _ (Ident tag)) -> "((" <> a <> ")[0] == " <> pyStr tag <> ")"

genOp2 :: BackendOperator2 -> String -> String -> String
genOp2 op a b = case op of
  OpArrayIndex -> "(" <> a <> ")[" <> b <> "]"
  OpBooleanAnd -> "((" <> a <> ") and (" <> b <> "))" -- handled in genOp; here for totality
  OpBooleanOr -> "((" <> a <> ") or (" <> b <> "))"
  OpBooleanOrd o -> cmp o
  OpCharOrd o -> cmp o
  OpIntOrd o -> cmp o
  OpNumberOrd o -> cmp o
  OpStringOrd o -> cmp o
  OpIntBitAnd -> bin "&"
  OpIntBitOr -> bin "|"
  OpIntBitXor -> bin "^"
  OpIntBitShiftLeft -> "_int32((" <> a <> ") << ((" <> b <> ") & 31))"
  OpIntBitShiftRight -> "(_int32(" <> a <> ") >> ((" <> b <> ") & 31))"
  OpIntBitZeroFillShiftRight -> "((_int32(" <> a <> ") & 0xFFFFFFFF) >> ((" <> b <> ") & 31))"
  OpIntNum OpDivide -> "_int_div(" <> a <> ", " <> b <> ")"
  OpIntNum o -> bin (numOp o)
  OpNumberNum OpDivide -> "_num_div(" <> a <> ", " <> b <> ")"
  OpNumberNum o -> bin (numOp o)
  OpStringAppend -> bin "+"
  where
  bin o = "((" <> a <> ") " <> o <> " (" <> b <> "))"
  cmp o = bin (ordOp o)

ordOp :: BackendOperatorOrd -> String
ordOp = case _ of
  OpEq -> "=="
  OpNotEq -> "!="
  OpGt -> ">"
  OpGte -> ">="
  OpLt -> "<"
  OpLte -> "<="

numOp :: BackendOperatorNum -> String
numOp = case _ of
  OpAdd -> "+"
  OpSubtract -> "-"
  OpMultiply -> "*"
  OpDivide -> "/" -- routed to _int_div / _num_div above; unreachable

-- | Run an effect NOW: emit its steps as statements in the CURRENT block and
-- | return the expression for its result.
-- |
-- | This is what keeps a long `do` block flat, and it is not an optimisation.
-- | Treating each `EffectBind` as an ordinary expression means building the
-- | continuation as its own thunk and immediately forcing it, which costs one
-- | level of indentation PER BIND -- and CPython refuses a file indented more
-- | than 100 levels, so a large enough `do` block would simply fail to parse.
-- | Walking the chain in effect mode turns N nested `def`s into N sibling
-- | statements inside one.
-- |
-- | A `Ref` is a one-element list, as in the shared `Effect.Ref` shim.
genEffect :: Env -> TcoExpr -> Gen String
genEffect env te@(TcoExpr _ syn) = case syn of
  EffectBind mbIdent lvl val body -> do
    v <- genEffect env val
    Tuple env' name <- bindLocal env mbIdent lvl
    emit (name <> " = " <> v)
    genEffect env' body

  EffectPure a -> genExpr env a

  EffectDefer a -> genEffect env a

  -- A pure `Let` sequenced inside an effect block: an assignment either way.
  Let mbIdent lvl val body -> do
    v <- genExpr env val
    Tuple env' name <- bindLocal env mbIdent lvl
    emit (name <> " = " <> v)
    genEffect env' body

  PrimEffect (EffectRefNew a) -> do
    v <- genExpr env a
    pure ("[" <> v <> "]")

  PrimEffect (EffectRefRead a) -> do
    v <- genExpr env a
    pure ("(" <> v <> ")[0]")

  PrimEffect (EffectRefWrite a b) -> do
    r <- genExpr env a
    v <- genExpr env b
    emit ("(" <> r <> ")[0] = " <> v)
    pure "None"

  -- Anything else evaluates to an `Effect a` value, which is a thunk: force it.
  _ -> do
    e <- genExpr env te
    pure ("(" <> e <> ")()")

--------------------------------------------------------------------------------
-- Emission helpers
--------------------------------------------------------------------------------

-- | A Python tuple literal. The trailing comma is required: `("Nothing")` is a
-- | string, `("Nothing",)` is the nullary constructor.
tupleLit :: Array String -> String
tupleLit xs = "(" <> commaSep xs <> ",)"

commaSep :: Array String -> String
commaSep = String.joinWith ", "

-- | A double-quoted Python string literal, escaped as `purepy`'s
-- | `escapeStringPy` does. The output file is UTF-8, so codepoints outside the
-- | escape set pass through raw.
pyStr :: String -> String
pyStr s = "\"" <> foldMap escapeChar (SCU.toCharArray s) <> "\""
  where
  escapeChar c = case c of
    '"' -> "\\\""
    '\\' -> "\\\\"
    '\n' -> "\\n"
    '\r' -> "\\r"
    '\t' -> "\\t"
    '\x8' -> "\\b"
    '\xc' -> "\\f"
    _ | toCharCode c < 0x20 -> "\\u" <> hex4 c
    _ -> SCU.singleton c

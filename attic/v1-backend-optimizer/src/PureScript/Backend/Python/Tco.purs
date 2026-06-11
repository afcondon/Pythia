-- | Tail Call Optimization for Python code generation
module PureScript.Backend.Python.Tco where

import Prelude

import Data.Array as Array
import Data.Array.NonEmpty as NonEmptyArray
import Data.Foldable (foldl)
import Data.Maybe (Maybe(..))
import Data.Tuple (Tuple(..), snd)
import PureScript.Backend.Optimizer.CoreFn (Ident(..), ModuleName, Qualified(..))
import PureScript.Backend.Optimizer.Codegen.Tco as Tco
import PureScript.Backend.Optimizer.Semantics (NeutralExpr(..))
import PureScript.Backend.Optimizer.Syntax (BackendSyntax(..), Level, Pair(..))
import PureScript.Backend.Optimizer.Syntax as Syn
import PureScript.Backend.Python.Convert (CodegenContext, codegenExpr, localIdent, toPyIdent)
import PureScript.Backend.Python.Syntax as Py

-- | Context for TCO code generation
type TcoCodegenContext =
  { baseCtx :: CodegenContext
  , tcoIdent :: Ident           -- The function being optimized
  , tcoArgs :: Array Py.PyIdent -- The argument identifiers for reassignment
  }

-- | Result of analyzing a binding for TCO eligibility
data TcoResult
  = TcoLoop
      { args :: Array (Tuple (Maybe Ident) Level)
      , body :: Tco.TcoExpr
      }
  | NotTco NeutralExpr

-- | Count total arity of nested lambdas and extract all arguments
-- | For `\a -> \b -> \c -> body`, returns (3, [a,b,c], body)
collectLambdaArgs :: NeutralExpr -> { arity :: Int, args :: Array (Tuple (Maybe Ident) Level), body :: NeutralExpr }
collectLambdaArgs (NeutralExpr syntax) = case syntax of
  Abs args (inner@(NeutralExpr (Abs _ _))) ->
    let rest = collectLambdaArgs inner
    in { arity: NonEmptyArray.length args + rest.arity
       , args: NonEmptyArray.toArray args <> rest.args
       , body: rest.body
       }
  Abs args body ->
    { arity: NonEmptyArray.length args
    , args: NonEmptyArray.toArray args
    , body: body  -- Just the body, not the whole Abs
    }
  UncurriedAbs args body ->
    { arity: Array.length args
    , args: args
    , body: body  -- Just the body, not the whole UncurriedAbs
    }
  _ ->
    { arity: 0, args: [], body: NeutralExpr syntax }

-- | Similar helper for TcoExpr
collectTcoLambdaArgs :: Tco.TcoExpr -> { arity :: Int, args :: Array (Tuple (Maybe Ident) Level), body :: Tco.TcoExpr }
collectTcoLambdaArgs tcoExpr@(Tco.TcoExpr _ syntax) = case syntax of
  Abs args (inner@(Tco.TcoExpr _ (Abs _ _))) ->
    let rest = collectTcoLambdaArgs inner
    in { arity: NonEmptyArray.length args + rest.arity
       , args: NonEmptyArray.toArray args <> rest.args
       , body: rest.body
       }
  Abs args body ->
    { arity: NonEmptyArray.length args
    , args: NonEmptyArray.toArray args
    , body: body
    }
  UncurriedAbs args body ->
    { arity: Array.length args
    , args: args
    , body: body
    }
  _ ->
    { arity: 0, args: [], body: tcoExpr }

-- | Check if an expression is a fully-applied self-call in tail position
-- | For curried functions, we need to detect patterns like: f x y z (where f has arity 3)
isSelfTailCall :: Qualified Ident -> Int -> NeutralExpr -> Boolean
isSelfTailCall selfRef expectedArity (NeutralExpr expr) = case expr of
  -- Direct variable reference (arity 0 function, though rare)
  Var ref | ref == selfRef && expectedArity == 0 -> true

  -- Uncurried application
  UncurriedApp (NeutralExpr (Var ref)) args
    | ref == selfRef && Array.length args == expectedArity -> true

  -- Curried application - count nested Apps
  App _ _ ->
    let { fn, argCount } = collectApps (NeutralExpr expr)
    in case fn of
      NeutralExpr (Var ref) | ref == selfRef && argCount == expectedArity -> true
      _ -> false

  -- Branch - check if ALL branches end in tail calls
  Branch branches def ->
    Array.all (\(Pair _ body) -> isSelfTailCall selfRef expectedArity body) (NonEmptyArray.toArray branches)
    && isSelfTailCall selfRef expectedArity def

  -- Let - check the body
  Let _ _ _ body -> isSelfTailCall selfRef expectedArity body
  LetRec _ _ body -> isSelfTailCall selfRef expectedArity body

  _ -> false

-- | Collect nested App calls to get the function and total argument count
collectApps :: NeutralExpr -> { fn :: NeutralExpr, argCount :: Int }
collectApps (NeutralExpr expr) = case expr of
  App fn args ->
    let inner = collectApps fn
    in { fn: inner.fn, argCount: inner.argCount + NonEmptyArray.length args }
  UncurriedApp fn args ->
    let inner = collectApps fn
    in { fn: inner.fn, argCount: inner.argCount + Array.length args }
  _ -> { fn: NeutralExpr expr, argCount: 0 }

-- | Check if a function body has a self-tail-call pattern
-- | The body might have branches where some lead to recursion and some don't
hasTailCallPattern :: Qualified Ident -> Int -> NeutralExpr -> Boolean
hasTailCallPattern selfRef expectedArity (NeutralExpr expr) = case expr of
  -- Branch with at least one recursive case
  Branch branches def ->
    let hasRecursive = Array.any (\(Pair _ body) -> hasTailCallPattern selfRef expectedArity body) (NonEmptyArray.toArray branches)
                    || hasTailCallPattern selfRef expectedArity def
        -- Also check that recursive calls are proper tail calls
        allTailCallsValid = Array.all (\(Pair _ body) -> isValidTailPosition selfRef expectedArity body) (NonEmptyArray.toArray branches)
                         && isValidTailPosition selfRef expectedArity def
    in hasRecursive && allTailCallsValid

  -- Let bindings - check body
  Let _ _ _ body -> hasTailCallPattern selfRef expectedArity body
  LetRec _ _ body -> hasTailCallPattern selfRef expectedArity body

  -- Direct tail call
  _ -> isSelfTailCall selfRef expectedArity (NeutralExpr expr)

-- | Check if expression is in valid tail position (either base case or proper tail call)
isValidTailPosition :: Qualified Ident -> Int -> NeutralExpr -> Boolean
isValidTailPosition selfRef expectedArity expr@(NeutralExpr syntax) = case syntax of
  -- Recursive tail call
  App _ _ -> isSelfTailCall selfRef expectedArity expr
  UncurriedApp _ _ -> isSelfTailCall selfRef expectedArity expr

  -- Branch - all branches must be valid
  Branch branches def ->
    Array.all (\(Pair _ body) -> isValidTailPosition selfRef expectedArity body) (NonEmptyArray.toArray branches)
    && isValidTailPosition selfRef expectedArity def

  -- Let - body must be valid
  Let _ _ _ body -> isValidTailPosition selfRef expectedArity body
  LetRec _ _ body -> isValidTailPosition selfRef expectedArity body

  -- Base case (non-recursive return) - always valid
  _ -> true

-- | Analyze a binding to see if it's TCO-eligible
-- | Returns TcoLoop if the function is self-tail-recursive
analyzeTco :: ModuleName -> Ident -> NeutralExpr -> TcoResult
analyzeTco modName ident expr@(NeutralExpr syntax) = case syntax of
  -- Check for curried functions (Abs)
  Abs _ _ -> do
    let collected = collectLambdaArgs (NeutralExpr syntax)
    let selfRef = Qualified (Just modName) ident
    -- Check if the innermost body has self-tail-call pattern
    if hasTailCallPattern selfRef collected.arity collected.body
      then
        -- Run the standard analysis for code generation
        let tcoEnv = [Tuple (Tco.TcoTopLevel selfRef) collected.arity]
            tcoExpr = Tco.analyze tcoEnv (NeutralExpr syntax)
            tcoCollected = collectTcoLambdaArgs tcoExpr
        in TcoLoop { args: tcoCollected.args, body: tcoCollected.body }
      else NotTco expr

  -- Check for uncurried functions (UncurriedAbs)
  UncurriedAbs args body -> do
    let selfRef = Qualified (Just modName) ident
    if hasTailCallPattern selfRef (Array.length args) body
      then
        let tcoEnv = [Tuple (Tco.TcoTopLevel selfRef) (Array.length args)]
            tcoExpr = Tco.analyze tcoEnv (NeutralExpr (UncurriedAbs args body))
            tcoCollected = collectTcoLambdaArgs tcoExpr
        in TcoLoop { args: tcoCollected.args, body: tcoCollected.body }
      else NotTco expr

  _ -> NotTco expr

-- | Generate a TCO-optimized function definition
-- | Returns statements that define the function
-- | For curried functions, also generates a curried wrapper
codegenTcoFunction :: CodegenContext -> Ident -> Array (Tuple (Maybe Ident) Level) -> Tco.TcoExpr -> Array Py.PyStmt
codegenTcoFunction baseCtx ident args body =
  let funcName = toPyIdent ident
      tcoFuncName = Py.PyIdent ("_tco_" <> unwrapIdent funcName)
      -- Generate parameter names (_copy0, _copy1, ...)
      copyParams = Array.mapWithIndex (\i _ -> Py.PyIdent ("_copy" <> show i)) args
      -- Generate local var names that match Local references
      localVars = map (\(Tuple _ lvl) -> localIdent lvl 0) args

      -- Create TCO context
      tcoCtx = { baseCtx, tcoIdent: ident, tcoArgs: localVars }

      -- Generate the function body:
      -- 1. Copy args to local vars
      -- 2. while True: body
      copyStmts = Array.zipWith
        (\local copy -> Py.PyAssign local (Py.PyVar copy))
        localVars
        copyParams

      bodyStmts = codegenTcoBody tcoCtx body
      whileStmt = Py.PyWhile (Py.PyLitBool true) bodyStmts

      -- The internal TCO function
      tcoFunc = Py.PyDef tcoFuncName copyParams (copyStmts <> [whileStmt])

      -- Generate curried wrapper: funcName = lambda a: lambda b: ... : _tco_func(a, b, ...)
      wrapperArgs = Array.mapWithIndex (\i _ -> Py.PyIdent ("_a" <> show i)) args
      innerCall = Py.PyCall (Py.PyVar tcoFuncName) (map Py.PyVar wrapperArgs)
      curriedWrapper = Array.foldr
        (\arg inner -> Py.PyLambda [arg] inner)
        innerCall
        wrapperArgs
      wrapperAssign = Py.PyAssign funcName curriedWrapper

  in [ tcoFunc, wrapperAssign ]
  where
  unwrapIdent (Py.PyIdent s) = s

-- | Generate statements for a TCO function body
-- | This is the key function that handles tail calls specially
codegenTcoBody :: TcoCodegenContext -> Tco.TcoExpr -> Array Py.PyStmt
codegenTcoBody ctx (Tco.TcoExpr _ expr) = case expr of
  -- Branch: if/else chain
  Branch branches def ->
    let branchStmts = codegenTcoBranches ctx (NonEmptyArray.toArray branches) def
    in branchStmts

  -- Let binding in statement context
  Let mbIdent lvl val body ->
    let varName = case mbIdent of
          Just ident -> toPyIdent ident
          Nothing -> localIdent lvl 0
        valExpr = codegenTcoExpr ctx val
    in [ Py.PyAssign varName valExpr ] <> codegenTcoBody ctx body

  -- Tail call to self: reassign args + continue
  App (Tco.TcoExpr _ (Var (Qualified (Just _) fnIdent))) args
    | fnIdent == ctx.tcoIdent ->
        let argExprs = map (codegenTcoExpr ctx) (NonEmptyArray.toArray args)
        in [ Py.PyMultiAssign ctx.tcoArgs argExprs, Py.PyContinue ]

  UncurriedApp (Tco.TcoExpr _ (Var (Qualified (Just _) fnIdent))) args
    | fnIdent == ctx.tcoIdent ->
        let argExprs = map (codegenTcoExpr ctx) args
        in [ Py.PyMultiAssign ctx.tcoArgs argExprs, Py.PyContinue ]

  -- Non-tail expression: return it
  _ ->
    [ Py.PyReturn (codegenTcoExpr ctx (Tco.TcoExpr mempty expr)) ]

-- | Generate if/else chain for branches
codegenTcoBranches :: TcoCodegenContext -> Array (Pair Tco.TcoExpr) -> Tco.TcoExpr -> Array Py.PyStmt
codegenTcoBranches ctx branches def = case Array.uncons branches of
  Nothing ->
    -- No more branches, generate default
    codegenTcoBody ctx def
  Just { head: Pair cond body, tail: rest } ->
    let condExpr = codegenTcoExpr ctx cond
        thenStmts = codegenTcoBody ctx body
        elseStmts = codegenTcoBranches ctx rest def
    in [ Py.PyIf condExpr thenStmts (Just elseStmts) ]

-- | Convert a TcoExpr to a Python expression (non-statement context)
codegenTcoExpr :: TcoCodegenContext -> Tco.TcoExpr -> Py.PyExpr
codegenTcoExpr ctx (Tco.TcoExpr _ expr) = case expr of
  Var qual ->
    codegenExpr ctx.baseCtx (NeutralExpr (Var qual))

  Local _mbIdent lvl ->
    Py.PyVar (localIdent lvl 0)

  Lit lit ->
    codegenExpr ctx.baseCtx (NeutralExpr (Lit (map (wrapNeutral ctx) lit)))

  App fn args ->
    let fnExpr = codegenTcoExpr ctx fn
        argExprs = map (codegenTcoExpr ctx) (NonEmptyArray.toArray args)
    in foldl (\acc arg -> Py.PyApp acc [arg]) fnExpr argExprs

  UncurriedApp fn args ->
    Py.PyApp (codegenTcoExpr ctx fn) (map (codegenTcoExpr ctx) args)

  Abs args body ->
    let params = map (\(Tuple _ lvl) -> localIdent lvl 0) (NonEmptyArray.toArray args)
    in Py.PyLambda params (codegenTcoExpr ctx body)

  UncurriedAbs args body ->
    Py.PyLambda (map (\(Tuple _ lvl) -> localIdent lvl 0) args) (codegenTcoExpr ctx body)

  Branch branches def ->
    let mkBranch (Pair cond body) rest =
          Py.PyTernary (codegenTcoExpr ctx cond) (codegenTcoExpr ctx body) rest
    in Array.foldr mkBranch (codegenTcoExpr ctx def) (NonEmptyArray.toArray branches)

  Let mbIdent lvl val body ->
    let varName = case mbIdent of
          Just ident -> toPyIdent ident
          Nothing -> localIdent lvl 0
        binding = Py.PyWalrus varName (codegenTcoExpr ctx val)
        bodyExpr = codegenTcoExpr ctx body
    in Py.PyCall
        (Py.PyLambda []
          (Py.PyIndex
            (Py.PyTuple [binding, bodyExpr])
            (Py.PyLitInt (-1))))
        []

  PrimOp op ->
    codegenTcoPrimOp ctx op

  Accessor e accessor ->
    codegenExpr ctx.baseCtx (NeutralExpr (Accessor (wrapNeutral ctx e) accessor))

  CtorSaturated _qual _ctorType _typeName (Ident ctorName) fields ->
    Py.pyConstructor ctorName (map (codegenTcoExpr ctx <<< snd) fields)

  Fail msg ->
    Py.PyCall (Py.pyVar "_runtime_fail") [Py.pyString msg]

  PrimUndefined ->
    Py.pyNone

  _ ->
    Py.PyCall (Py.pyVar "_unimplemented") [Py.pyString "unhandled TCO expression"]

-- | Convert TcoExpr back to NeutralExpr (for reusing non-TCO codegen)
wrapNeutral :: TcoCodegenContext -> Tco.TcoExpr -> NeutralExpr
wrapNeutral _ (Tco.TcoExpr _ expr) = NeutralExpr (map (wrapNeutralInner) expr)
  where
  wrapNeutralInner (Tco.TcoExpr _ e) = NeutralExpr (map wrapNeutralInner e)

-- | Handle primitive operations in TCO context
codegenTcoPrimOp :: TcoCodegenContext -> Syn.BackendOperator Tco.TcoExpr -> Py.PyExpr
codegenTcoPrimOp ctx = case _ of
  Syn.Op1 op arg ->
    case op of
      Syn.OpBooleanNot -> Py.PyUnaryOp "not" (codegenTcoExpr ctx arg)
      Syn.OpIntBitNot -> Py.PyUnaryOp "~" (codegenTcoExpr ctx arg)
      Syn.OpIntNegate -> Py.PyUnaryOp "-" (codegenTcoExpr ctx arg)
      Syn.OpNumberNegate -> Py.PyUnaryOp "-" (codegenTcoExpr ctx arg)
      Syn.OpArrayLength -> Py.PyCall (Py.pyVar "len") [codegenTcoExpr ctx arg]
      Syn.OpIsTag (Qualified _ (Ident tag)) ->
        Py.PyBinOp "==" (Py.PyIndex (codegenTcoExpr ctx arg) (Py.pyInt 0)) (Py.pyString tag)

  Syn.Op2 op l r ->
    let left = codegenTcoExpr ctx l
        right = codegenTcoExpr ctx r
    in case op of
      Syn.OpIntNum Syn.OpAdd -> Py.PyBinOp "+" left right
      Syn.OpIntNum Syn.OpSubtract -> Py.PyBinOp "-" left right
      Syn.OpIntNum Syn.OpMultiply -> Py.PyBinOp "*" left right
      Syn.OpIntNum Syn.OpDivide -> Py.PyBinOp "//" left right
      Syn.OpNumberNum Syn.OpAdd -> Py.PyBinOp "+" left right
      Syn.OpNumberNum Syn.OpSubtract -> Py.PyBinOp "-" left right
      Syn.OpNumberNum Syn.OpMultiply -> Py.PyBinOp "*" left right
      Syn.OpNumberNum Syn.OpDivide -> Py.PyBinOp "/" left right
      Syn.OpIntBitAnd -> Py.PyBinOp "&" left right
      Syn.OpIntBitOr -> Py.PyBinOp "|" left right
      Syn.OpIntBitXor -> Py.PyBinOp "^" left right
      Syn.OpIntBitShiftLeft -> Py.PyBinOp "<<" left right
      Syn.OpIntBitShiftRight -> Py.PyBinOp ">>" left right
      Syn.OpIntBitZeroFillShiftRight -> Py.PyBinOp ">>" left right
      Syn.OpIntOrd cmp -> codegenTcoCompare cmp left right
      Syn.OpNumberOrd cmp -> codegenTcoCompare cmp left right
      Syn.OpStringOrd cmp -> codegenTcoCompare cmp left right
      Syn.OpCharOrd cmp -> codegenTcoCompare cmp left right
      Syn.OpBooleanOrd cmp -> codegenTcoCompare cmp left right
      Syn.OpBooleanAnd -> Py.PyBinOp "and" left right
      Syn.OpBooleanOr -> Py.PyBinOp "or" left right
      Syn.OpStringAppend -> Py.PyBinOp "+" left right
      Syn.OpArrayIndex -> Py.PyIndex left right

-- | Convert comparison operators in TCO context
codegenTcoCompare :: Syn.BackendOperatorOrd -> Py.PyExpr -> Py.PyExpr -> Py.PyExpr
codegenTcoCompare cmp left right = case cmp of
  Syn.OpEq -> Py.PyBinOp "==" left right
  Syn.OpNotEq -> Py.PyBinOp "!=" left right
  Syn.OpLt -> Py.PyBinOp "<" left right
  Syn.OpLte -> Py.PyBinOp "<=" left right
  Syn.OpGt -> Py.PyBinOp ">" left right
  Syn.OpGte -> Py.PyBinOp ">=" left right

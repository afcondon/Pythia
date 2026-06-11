-- | Convert optimizer IR to Python AST
module PureScript.Backend.Python.Convert where

import Prelude

import Data.Array as Array
import Data.Array.NonEmpty as NonEmptyArray
import Data.Foldable (foldl, foldr)
import Data.Maybe (Maybe(..))
import Data.String as String
import Data.String.CodeUnits as SCU
import Data.Tuple (Tuple(..))
import PureScript.Backend.Optimizer.CoreFn (Ident(..), Literal(..), ModuleName(..), Prop(..), Qualified(..))
import PureScript.Backend.Optimizer.Semantics (NeutralExpr(..))
import PureScript.Backend.Optimizer.Syntax (BackendAccessor(..), BackendSyntax(..), Level(..), Pair(..))
import PureScript.Backend.Optimizer.Syntax as Syn
import PureScript.Backend.Python.Syntax as Py

-- | Codegen context containing current module information
type CodegenContext =
  { currentModule :: ModuleName
  }

-- | Convert a module name to Python module name
toPyModuleName :: ModuleName -> String
toPyModuleName (ModuleName name) = name
  # String.replaceAll (String.Pattern ".") (String.Replacement "_")
  # String.toLower

-- | Convert an identifier to Python identifier
toPyIdent :: Ident -> Py.PyIdent
toPyIdent (Ident name) = Py.PyIdent (sanitizeIdent name)

-- | Sanitize an identifier for Python
sanitizeIdent :: String -> String
sanitizeIdent name
  | isPythonReserved name = name <> "_"
  | otherwise = name
  # String.replaceAll (String.Pattern "'") (String.Replacement "_prime")
  # String.replaceAll (String.Pattern "$") (String.Replacement "_dollar_")

-- | Check if a name is a Python reserved word
isPythonReserved :: String -> Boolean
isPythonReserved name = Array.elem name
  [ "False", "None", "True", "and", "as", "assert", "async", "await"
  , "break", "class", "continue", "def", "del", "elif", "else", "except"
  , "finally", "for", "from", "global", "if", "import", "in", "is"
  , "lambda", "nonlocal", "not", "or", "pass", "raise", "return", "try"
  , "while", "with", "yield"
  -- Also shadow builtins that might conflict
  , "type", "id", "input", "print", "list", "dict", "set", "str", "int"
  , "float", "bool", "len", "range", "map", "filter", "sum", "min", "max"
  ]

-- | Convert a local variable reference
localIdent :: Level -> Int -> Py.PyIdent
localIdent (Level lvl) idx = Py.PyIdent ("_v" <> show lvl <> "_" <> show idx)

-- | Main conversion function: optimizer IR to Python expression
-- | Takes a context with the current module name to avoid self-qualified references
codegenExpr :: CodegenContext -> NeutralExpr -> Py.PyExpr
codegenExpr ctx (NeutralExpr expr) = case expr of
  -- Variables
  Var (Qualified (Just mod@(ModuleName modName)) (Ident name))
    -- If referencing the current module, emit unqualified
    | mod == ctx.currentModule ->
        Py.pyVar (sanitizeIdent name)
    | otherwise ->
        let pyMod = modName
              # String.replaceAll (String.Pattern ".") (String.Replacement "_")
              # String.toLower
        in Py.PyAccess (Py.pyVar pyMod) (sanitizeIdent name)

  Var (Qualified Nothing (Ident name)) ->
    Py.pyVar (sanitizeIdent name)

  -- Local bindings (de Bruijn-ish levels)
  Local _ lvl ->
    Py.PyVar (localIdent lvl 0)

  -- Literals
  Lit lit -> codegenLiteral ctx lit

  -- Uncurried function (optimized form)
  -- Always use localIdent for parameter names so they match Local references
  UncurriedAbs args body ->
    Py.PyLambda (map (\(Tuple _ lvl) -> localIdent lvl 0) args) (codegenExpr ctx body)

  -- Curried function (fallback) - generates nested lambdas
  Abs args body ->
    foldr mkLambda (codegenExpr ctx body) (NonEmptyArray.toArray args)
    where
    mkLambda (Tuple _ lvl) inner =
      Py.PyLambda [localIdent lvl 0] inner

  -- Uncurried application (optimized form)
  UncurriedApp fn args ->
    Py.PyApp (codegenExpr ctx fn) (map (codegenExpr ctx) args)

  -- Curried application (fallback) - applies args one at a time
  App fn args ->
    foldl (\acc arg -> Py.PyApp acc [codegenExpr ctx arg]) (codegenExpr ctx fn) (NonEmptyArray.toArray args)

  -- Let binding: Let (Maybe Ident) Level value body
  Let _mbIdent lvl val body ->
    -- Use Python's walrus operator in a lambda-immediately-invoked pattern
    -- (lambda: ((x := val), body)[-1])()
    -- IMPORTANT: Always use localIdent for the binding name, because Local references
    -- use localIdent. The mbIdent is just for debugging, Level is what matters.
    let varName = localIdent lvl 0
        binding = Py.PyWalrus varName (codegenExpr ctx val)
        bodyExpr = codegenExpr ctx body
    in Py.PyCall
        (Py.PyLambda []
          (Py.PyIndex
            (Py.PyTuple [binding, bodyExpr])
            (Py.PyLitInt (-1))))
        []

  -- Recursive let bindings: LetRec Level (NonEmptyArray (Tuple Ident value)) body
  -- IMPORTANT: Must use localIdent (not toPyIdent) so binding names match Local references
  -- Local references use localIdent to generate names like _v4_0, so we must do the same here
  LetRec lvl bindings body ->
    -- Use localIdent for consistency with how Local references are generated
    -- For multiple bindings sharing the same Level, we append the index
    let bindingExprs = Array.mapWithIndex (\idx (Tuple _ident val) ->
          Py.PyWalrus (localIdent lvl idx) (codegenExpr ctx val)) (NonEmptyArray.toArray bindings)
        bodyExpr = codegenExpr ctx body
    in Py.PyCall
        (Py.PyLambda []
          (Py.PyIndex
            (Py.PyTuple (Array.snoc bindingExprs bodyExpr))
            (Py.PyLitInt (-1))))
        []

  -- Branching (conditionals)
  Branch branches def ->
    foldr mkBranch (codegenExpr ctx def) (NonEmptyArray.toArray branches)
    where
    mkBranch (Pair cond body) rest =
      Py.PyTernary (codegenExpr ctx cond) (codegenExpr ctx body) rest

  -- Constructor definition: CtorDef ConstructorType ProperName Ident (Array String)
  -- Generates a curried function that creates a tagged tuple
  CtorDef _ctorType _typeName (Ident ctorName) fields ->
    case Array.length fields of
      0 ->
        -- No-arg constructor: just a tuple with the tag
        Py.PyTuple [Py.pyString ctorName]
      _ ->
        -- Constructor with fields: curried lambda that returns tagged tuple
        -- Each field becomes a nested lambda: lambda _0: lambda _1: ... ("Tag", _0, _1, ...)
        let params = Array.mapWithIndex (\i _ -> Py.PyIdent ("_" <> show i)) fields
            fieldExprs = Array.mapWithIndex (\i _ -> Py.pyVar ("_" <> show i)) fields
            body = Py.PyTuple (Array.cons (Py.pyString ctorName) fieldExprs)
        in foldr (\param inner -> Py.PyLambda [param] inner) body params

  -- Constructor (saturated): CtorSaturated (Qualified Ident) ConstructorType ProperName Ident (Array (Tuple String a))
  -- The Ident (4th arg) is the constructor name, ProperName (3rd arg) is the type name
  CtorSaturated _ _ _ (Ident ctorName) fields ->
    Py.pyConstructor ctorName (map (codegenExpr ctx <<< snd) fields)
    where
    snd (Tuple _ x) = x

  -- Record/array accessor
  Accessor e accessor ->
    case accessor of
      GetProp field -> Py.PyIndex (codegenExpr ctx e) (Py.pyString field)
      GetIndex idx -> Py.PyIndex (codegenExpr ctx e) (Py.pyInt idx)
      -- Constructor fields: use index+1 since index 0 is the tag
      GetCtorField _ _ _ _ _ idx -> Py.PyIndex (codegenExpr ctx e) (Py.pyInt (idx + 1))

  -- Record update: Update a (Array (Prop a))
  Update e updates ->
    Py.PyLitObject
      (Array.cons
        (Tuple "**" (codegenExpr ctx e))
        (map (\(Prop k v) -> Tuple k (codegenExpr ctx v)) updates))

  -- Primitive operations
  PrimOp op ->
    codegenPrimOp ctx op

  -- Effect operations: EffectBind (Maybe Ident) Level effect body
  EffectBind _mbIdent lvl eff body ->
    -- Effectful code: (lambda: ((x := eff()), body())[-1])()
    -- IMPORTANT: Always use localIdent for consistency with Local references
    let varName = localIdent lvl 0
        effCall = Py.PyCall (codegenExpr ctx eff) []
        binding = Py.PyWalrus varName effCall
        bodyExpr = Py.PyCall (codegenExpr ctx body) []
    in Py.PyCall
        (Py.PyLambda []
          (Py.PyIndex
            (Py.PyTuple [binding, bodyExpr])
            (Py.PyLitInt (-1))))
        []

  EffectPure val ->
    -- Pure effect: lambda: val
    Py.PyLambda [] (codegenExpr ctx val)

  EffectDefer body ->
    -- Deferred effect: lambda: body()
    Py.PyLambda [] (Py.PyCall (codegenExpr ctx body) [])

  -- Uncurried effect app
  UncurriedEffectApp fn args ->
    Py.PyCall (Py.PyApp (codegenExpr ctx fn) (map (codegenExpr ctx) args)) []

  -- Fail (runtime error)
  Fail msg ->
    Py.PyCall (Py.pyVar "_runtime_fail") [Py.pyString msg]

  -- Undefined
  PrimUndefined ->
    Py.pyNone

  -- Catch-all for unhandled cases
  _ ->
    Py.PyCall (Py.pyVar "_unimplemented") [Py.pyString "unhandled expression"]

-- | Convert a literal value
codegenLiteral :: CodegenContext -> Literal NeutralExpr -> Py.PyExpr
codegenLiteral ctx = case _ of
  LitInt n -> Py.pyInt n
  LitNumber n -> Py.PyLitNumber n
  LitString s -> Py.pyString s
  LitChar c -> Py.pyString (SCU.singleton c)
  LitBoolean b -> Py.pyBool b
  LitArray items -> Py.PyLitArray (map (codegenExpr ctx) items)
  LitRecord fields ->
    Py.PyLitObject (map (\(Prop k v) -> Tuple k (codegenExpr ctx v)) fields)

-- | Convert primitive operations
codegenPrimOp :: CodegenContext -> Syn.BackendOperator NeutralExpr -> Py.PyExpr
codegenPrimOp ctx = case _ of
  Syn.Op1 op arg ->
    case op of
      Syn.OpBooleanNot -> Py.PyUnaryOp "not" (codegenExpr ctx arg)
      Syn.OpIntBitNot -> Py.PyUnaryOp "~" (codegenExpr ctx arg)
      Syn.OpIntNegate -> Py.PyUnaryOp "-" (codegenExpr ctx arg)
      Syn.OpNumberNegate -> Py.PyUnaryOp "-" (codegenExpr ctx arg)
      Syn.OpArrayLength ->
        Py.PyCall (Py.pyVar "len") [codegenExpr ctx arg]
      Syn.OpIsTag (Qualified _ (Ident tag)) ->
        Py.PyBinOp "=="
          (Py.PyIndex (codegenExpr ctx arg) (Py.pyInt 0))
          (Py.pyString tag)

  Syn.Op2 op l r ->
    let left = codegenExpr ctx l
        right = codegenExpr ctx r
    in case op of
      -- Integer arithmetic (uses OpIntNum wrapper)
      Syn.OpIntNum Syn.OpAdd -> Py.PyBinOp "+" left right
      Syn.OpIntNum Syn.OpSubtract -> Py.PyBinOp "-" left right
      Syn.OpIntNum Syn.OpMultiply -> Py.PyBinOp "*" left right
      Syn.OpIntNum Syn.OpDivide -> Py.PyBinOp "//" left right

      -- Number arithmetic (uses OpNumberNum wrapper)
      Syn.OpNumberNum Syn.OpAdd -> Py.PyBinOp "+" left right
      Syn.OpNumberNum Syn.OpSubtract -> Py.PyBinOp "-" left right
      Syn.OpNumberNum Syn.OpMultiply -> Py.PyBinOp "*" left right
      Syn.OpNumberNum Syn.OpDivide -> Py.PyBinOp "/" left right

      -- Bitwise
      Syn.OpIntBitAnd -> Py.PyBinOp "&" left right
      Syn.OpIntBitOr -> Py.PyBinOp "|" left right
      Syn.OpIntBitXor -> Py.PyBinOp "^" left right
      Syn.OpIntBitShiftLeft -> Py.PyBinOp "<<" left right
      Syn.OpIntBitShiftRight -> Py.PyBinOp ">>" left right
      Syn.OpIntBitZeroFillShiftRight ->
        -- Python doesn't have unsigned right shift, need to handle specially
        Py.PyBinOp ">>" left right

      -- Comparison
      Syn.OpIntOrd cmp -> codegenCompare cmp left right
      Syn.OpNumberOrd cmp -> codegenCompare cmp left right
      Syn.OpStringOrd cmp -> codegenCompare cmp left right
      Syn.OpCharOrd cmp -> codegenCompare cmp left right
      Syn.OpBooleanOrd cmp -> codegenCompare cmp left right

      -- Boolean
      Syn.OpBooleanAnd -> Py.PyBinOp "and" left right
      Syn.OpBooleanOr -> Py.PyBinOp "or" left right

      -- String
      Syn.OpStringAppend -> Py.PyBinOp "+" left right

      -- Array
      Syn.OpArrayIndex ->
        Py.PyIndex left right

-- | Convert comparison operators
codegenCompare :: Syn.BackendOperatorOrd -> Py.PyExpr -> Py.PyExpr -> Py.PyExpr
codegenCompare cmp left right = case cmp of
  Syn.OpEq -> Py.PyBinOp "==" left right
  Syn.OpNotEq -> Py.PyBinOp "!=" left right
  Syn.OpLt -> Py.PyBinOp "<" left right
  Syn.OpLte -> Py.PyBinOp "<=" left right
  Syn.OpGt -> Py.PyBinOp ">" left right
  Syn.OpGte -> Py.PyBinOp ">=" left right

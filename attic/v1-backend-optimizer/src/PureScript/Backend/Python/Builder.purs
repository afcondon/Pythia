-- | Builder module that integrates with purescript-backend-optimizer
module PureScript.Backend.Python.Builder where

import Prelude

import Data.Array as Array
import Data.Either (isRight)
import Data.Maybe (Maybe(..), fromMaybe)
import Data.Set as Set
import Data.String as String
import Data.String.Pattern (Pattern(..))
import Data.Tuple (Tuple(..))
import Effect.Aff (Aff, attempt)
import Effect.Class.Console as Console
import Node.Encoding (Encoding(..))
import Node.FS.Aff as FS
import Node.Path as Path
import Node.Path (extname)
import PureScript.Backend.Optimizer.Convert (BackendModule)
import PureScript.Backend.Optimizer.CoreFn (Ident(..), ModuleName(..))
import PureScript.Backend.Optimizer.Semantics (NeutralExpr)
import PureScript.Backend.Python.Convert (CodegenContext, codegenExpr, sanitizeIdent, toPyModuleName)
import PureScript.Backend.Python.Tco as Tco
import PureScript.Backend.Python.Printer (escapeString)
import PureScript.Backend.Python.Syntax as Py

-- | Options for Python codegen
type PythonBuildOptions =
  { outputDir :: String
  , inputDir :: String
  }

-- | Generate Python code for a single binding
-- | Checks if the binding is TCO-eligible and generates optimized code if so
codegenBinding :: ModuleName -> CodegenContext -> Tuple Ident NeutralExpr -> String
codegenBinding modName ctx (Tuple ident@(Ident name) expr) =
  case Tco.analyzeTco modName ident expr of
    Tco.TcoLoop { args, body } ->
      -- Generate TCO-optimized function definition
      let stmts = Tco.codegenTcoFunction ctx ident args body
      in String.joinWith "\n" (map (printStmt 0) stmts)
    Tco.NotTco _ ->
      -- Generate regular assignment
      sanitizeIdent name <> " = " <> printExpr (codegenExpr ctx expr)

-- | Generate Python code for a binding group
codegenBindingGroup :: ModuleName -> CodegenContext -> { recursive :: Boolean, bindings :: Array (Tuple Ident NeutralExpr) } -> String
codegenBindingGroup modName ctx { recursive: false, bindings } =
  String.joinWith "\n" (map (codegenBinding modName ctx) bindings)
codegenBindingGroup modName ctx { recursive: true, bindings } =
  -- For recursive bindings, we need to define all names first, then assign
  -- Skip forward declarations for TCO functions (they're defined with def, not assignment)
  let isTcoBinding (Tuple ident expr) = case Tco.analyzeTco modName ident expr of
        Tco.TcoLoop _ -> true
        Tco.NotTco _ -> false
      nonTcoBindings = Array.filter (not <<< isTcoBinding) bindings
      names = map (\(Tuple (Ident n) _) -> sanitizeIdent n) nonTcoBindings
      forwardDecls = map (\n -> n <> " = None  # forward declaration") names
      assigns = map (codegenBinding modName ctx) bindings
  in String.joinWith "\n" (forwardDecls <> assigns)

-- | Generate the foreign module name for a given module
pyForeignModuleName :: ModuleName -> String
pyForeignModuleName modName = toPyModuleName modName <> "_foreign"

-- | Set of foreign function names that are provided by the Python runtime
-- | These don't need to be imported from _foreign modules
runtimeProvidedForeign :: Set.Set String
runtimeProvidedForeign = Set.fromFoldable
  [ -- Data.Unit
    "unit"
  -- Data.Semiring
  , "intAdd", "intMul", "numAdd", "numMul"
  -- Data.Ring
  , "intSub", "numSub"
  -- Data.EuclideanRing
  , "intDiv", "intMod", "numDiv", "intDegree"
  -- Data.Eq
  , "eqBooleanImpl", "eqIntImpl", "eqNumberImpl", "eqCharImpl", "eqStringImpl", "eqArrayImpl"
  -- Data.Ord
  , "ordBooleanImpl", "ordIntImpl", "ordNumberImpl", "ordCharImpl", "ordStringImpl", "ordArrayImpl"
  -- Data.HeytingAlgebra
  , "boolConj", "boolDisj", "boolNot"
  -- Data.Bounded
  , "topInt", "bottomInt", "topChar", "bottomChar", "topNumber", "bottomNumber"
  -- Data.Show
  , "showIntImpl", "showNumberImpl", "showCharImpl", "showStringImpl", "showArrayImpl"
  -- Data.Semigroup
  , "concatString", "concatArray"
  -- Data.Array
  , "indexImpl", "length", "concat", "filter", "reverse", "sortByImpl", "slice"
  , "range", "replicate", "zipWith", "take", "drop", "cons", "snoc", "uncons"
  , "_deleteAt", "_insertAt", "_updateAt", "allImpl", "anyImpl", "filterImpl"
  , "findIndexImpl", "findLastIndexImpl", "findMapImpl", "fromFoldableImpl"
  , "partitionImpl", "rangeImpl", "replicateImpl", "scanlImpl", "scanrImpl"
  , "sliceImpl", "unconsImpl", "unsafeIndexImpl", "zipWithImpl"
  -- Data.Array.ST
  , "cloneImpl", "freezeImpl", "lengthImpl", "peekImpl", "pokeImpl"
  , "popImpl", "pushAllImpl", "pushImpl", "shiftImpl", "spliceImpl"
  , "thawImpl", "toAssocArrayImpl", "unsafeFreezeImpl", "unsafeThawImpl", "unshiftAllImpl"
  -- Data.FunctorWithIndex
  , "mapWithIndexArray"
  -- Data.Traversable
  , "traverseArrayImpl"
  -- Data.Foldable
  , "foldlArray", "foldrArray"
  -- Data.Functor
  , "arrayMap"
  -- Control.Bind
  , "arrayBind"
  -- Control.Apply
  , "arrayApply"
  -- Control.Extend
  , "arrayExtend"
  -- Record.Unsafe
  , "unsafeGet", "unsafeSet", "unsafeHas", "unsafeDelete"
  -- Unsafe.Coerce
  , "unsafeCoerce"
  -- Effect
  , "pureE", "bindE", "untilE", "whileE", "forE", "foreachE"
  -- Effect.Console
  , "log", "warn", "error", "info", "debug"
  , "group", "groupCollapsed", "groupEnd"
  , "time", "timeEnd", "timeLog", "clear"
  -- Effect.Ref
  , "_new", "_read", "_modify", "_write", "modifyImpl", "newWithSelf"
  , "new", "read", "write", "modify"
  -- Effect.Unsafe
  , "unsafePerformEffect"
  -- Partial.Unsafe
  , "unsafePartial", "_unsafePartial", "_crashWith"
  -- Control.Monad.ST.Internal (same as Effect, just different naming)
  -- Note: PureScript uses "while" and "for" but they get sanitized to "while_" and "for_"
  , "pure_", "bind_", "map_", "run", "while", "for", "foreach"
  -- Control.Monad.ST.Uncurried
  , "mkSTFn1", "mkSTFn2", "mkSTFn3", "mkSTFn4", "mkSTFn5"
  , "mkSTFn6", "mkSTFn7", "mkSTFn8", "mkSTFn9", "mkSTFn10"
  , "runSTFn1", "runSTFn2", "runSTFn3", "runSTFn4", "runSTFn5"
  , "runSTFn6", "runSTFn7", "runSTFn8", "runSTFn9", "runSTFn10"
  -- Data.Function.Uncurried
  , "mkFn0", "mkFn2", "mkFn3", "mkFn4", "mkFn5", "mkFn6", "mkFn7", "mkFn8", "mkFn9", "mkFn10"
  , "runFn0", "runFn2", "runFn3", "runFn4", "runFn5", "runFn6", "runFn7", "runFn8", "runFn9", "runFn10"
  -- Effect.Uncurried
  , "mkEffectFn1", "mkEffectFn2", "mkEffectFn3", "mkEffectFn4", "mkEffectFn5"
  , "mkEffectFn6", "mkEffectFn7", "mkEffectFn8", "mkEffectFn9", "mkEffectFn10"
  , "runEffectFn1", "runEffectFn2", "runEffectFn3", "runEffectFn4", "runEffectFn5"
  , "runEffectFn6", "runEffectFn7", "runEffectFn8", "runEffectFn9", "runEffectFn10"
  -- Data.Unfoldable1
  , "unfoldr1ArrayImpl"
  -- Data.Unfoldable
  , "unfoldrArrayImpl"
  -- Data.Array.NonEmpty.Internal
  , "foldl1Impl", "foldr1Impl", "traverse1Impl"
  -- Data.Show.Generic
  , "intercalate"
  -- Control.Monad.Rec.Class
  , "tailRec", "Loop", "Done"
  -- Control.Monad.Asyncio
  , "pureAsyncio", "bindAsyncio", "mapAsyncio", "applyAsyncio"
  , "runAsyncio", "sleep", "forkAsyncio", "awaitTask", "cancelTask"
  , "parallelImpl", "raceAsyncio", "attemptAsyncio", "throwErrorAsyncio"
  , "catchErrorAsyncio", "bracketAsyncio", "liftEffectAsyncio"
  ]

-- | Generate a complete Python module from a BackendModule
codegenModule :: BackendModule -> String
codegenModule mod =
  let ModuleName modName = mod.name
      ctx = { currentModule: mod.name } :: CodegenContext

      -- Generate import statements
      imports = Array.fromFoldable mod.imports
      importLines = map (\(ModuleName imp) ->
        "import " <> toPyModuleName (ModuleName imp) <> " as " <> toPyModuleName (ModuleName imp)
      ) imports

      -- Generate foreign import statement if there are foreign bindings
      -- Filter out functions that are already provided by the runtime
      allForeignIdents = Array.fromFoldable mod.foreign
      foreignIdents = Array.filter (\(Ident n) -> not (Set.member n runtimeProvidedForeign)) allForeignIdents
      foreignLine = if Array.null foreignIdents
        then ""
        else "from " <> pyForeignModuleName mod.name <> " import " <>
             String.joinWith ", " (map (\(Ident n) -> sanitizeIdent n) foreignIdents)

      -- Generate bindings
      bindingLines = map (codegenBindingGroup mod.name ctx) mod.bindings

      -- Generate exports (as __all__)
      exports = Array.fromFoldable mod.exports
      exportNames = map (\(Ident n) -> "\"" <> sanitizeIdent n <> "\"") exports
      allLine = "__all__ = [" <> String.joinWith ", " exportNames <> "]"

  in String.joinWith "\n"
    [ "# Generated by purescript-backend-python"
    , "# Module: " <> modName
    , "# Do not edit this file directly"
    , ""
    , "from purepy_runtime import *"
    , ""
    , String.joinWith "\n" importLines
    , if foreignLine == "" then "" else foreignLine
    , ""
    , String.joinWith "\n\n" bindingLines
    , ""
    , allLine
    , ""
    ]

-- | Process a single module with the optimizer and generate Python
processModule :: PythonBuildOptions -> BackendModule -> String -> Aff Unit
processModule opts mod coreFnPath = do
  let pyModName = toPyModuleName mod.name
      pyCode = codegenModule mod
      outPath = Path.concat [opts.outputDir, pyModName <> ".py"]

  FS.writeTextFile UTF8 outPath pyCode
  Console.log $ "Generated: " <> pyModName <> ".py"

  -- Handle foreign imports (only for functions not provided by runtime)
  let allForeignIdents = Array.fromFoldable mod.foreign
      nonRuntimeForeign = Array.filter (\(Ident n) -> not (Set.member n runtimeProvidedForeign)) allForeignIdents
  unless (Array.null nonRuntimeForeign) do
    let foreignOutputPath = Path.concat [opts.outputDir, pyForeignModuleName mod.name <> ".py"]
        -- The CoreFn modulePath is something like "src/FFITest.purs" (relative to project root)
        -- We need to find the sibling .py file by replacing .purs with .py
        -- The input directory (e.g., "output") is the CoreFn output, so we go up one level
        projectRoot = Path.concat [opts.inputDir, ".."]
        moduleBasePath = fromMaybe coreFnPath (String.stripSuffix (Pattern (extname coreFnPath)) coreFnPath)
        foreignSiblingPath = Path.concat [projectRoot, moduleBasePath <> ".py"]

    result <- attempt $ copyFile foreignSiblingPath foreignOutputPath
    case isRight result of
      true -> Console.log $ "  Copied foreign: " <> pyForeignModuleName mod.name <> ".py"
      false -> Console.log $ "  Warning: Foreign implementation missing for " <> pyModName

-- | Copy a file
copyFile :: String -> String -> Aff Unit
copyFile src dst = do
  content <- FS.readTextFile UTF8 src
  FS.writeTextFile UTF8 dst content

-- | Generate Python runtime support module
generateRuntime :: String -> Aff Unit
generateRuntime outputDir = do
  let runtimePath = Path.concat [outputDir, "purepy_runtime.py"]
  FS.writeTextFile UTF8 runtimePath runtimeCode
  where
  runtimeCode = String.joinWith "\n"
    [ "# PureScript Python Runtime"
    , "# Generated by purescript-backend-python"
    , ""
    , "# Explicit __all__ to include underscore-prefixed names"
    , "__all__ = ["
    , "    'unit', '_runtime_fail', '_unimplemented', '_runtime_lazy', '_crashWith', '_unsafePartial',"
    , "    'boolConj', 'boolDisj', 'boolNot',"
    , "    'intAdd', 'intSub', 'intMul', 'intDiv', 'intMod', 'intDegree',"
    , "    'numAdd', 'numSub', 'numMul', 'numDiv',"
    , "    'topInt', 'bottomInt', 'topChar', 'bottomChar', 'topNumber', 'bottomNumber',"
    , "    'eqBooleanImpl', 'eqIntImpl', 'eqNumberImpl', 'eqCharImpl', 'eqStringImpl', 'eqArrayImpl',"
    , "    'ordBooleanImpl', 'ordIntImpl', 'ordNumberImpl', 'ordCharImpl', 'ordStringImpl', 'ordArrayImpl',"
    , "    'showIntImpl', 'showNumberImpl', 'showCharImpl', 'showStringImpl', 'showArrayImpl',"
    , "    'concatString', 'length', 'lengthImpl', 'indexImpl', 'concat', 'concatArray',"
    , "    'rangeImpl', 'replicateImpl', 'reverse', 'filterImpl', 'sortByImpl', 'sliceImpl',"
    , "    'zipWithImpl', 'unsafeIndexImpl', 'foldlArray', 'foldrArray',"
    , "    '_insertAt', '_deleteAt', '_updateAt', 'allImpl', 'anyImpl',"
    , "    'findIndexImpl', 'findLastIndexImpl', 'findMapImpl', 'partitionImpl',"
    , "    'unconsImpl', 'fromFoldableImpl', 'scanlImpl', 'scanrImpl',"
    , "    'thawImpl', 'freezeImpl', 'unsafeThawImpl', 'unsafeFreezeImpl', 'cloneImpl',"
    , "    'peekImpl', 'pokeImpl', 'pushImpl', 'pushAllImpl', 'popImpl',"
    , "    'shiftImpl', 'unshiftAllImpl', 'spliceImpl', 'toAssocArrayImpl',"
    , "    'mapWithIndexArray', 'traverseArrayImpl',"
    , "    'arrayMap', 'arrayBind', 'arrayApply', 'arrayExtend',"
    , "    'unfoldr1ArrayImpl', 'unfoldrArrayImpl',"
    , "    'foldl1Impl', 'foldr1Impl', 'traverse1Impl',"
    , "    'intercalate',"
    , "    'unsafeGet', 'unsafeSet', 'unsafeHas', 'unsafeDelete', 'unsafeCoerce',"
    , "    'pureE', 'bindE', 'untilE', 'whileE', 'forE', 'foreachE', 'unsafePerformEffect',"
    , "    'log', 'warn', 'error', 'info', 'debug', 'group', 'groupCollapsed', 'groupEnd',"
    , "    'time', 'timeLog', 'timeEnd', 'clear', '_console_timers',"
    , "    'Ref', '_new', '_read', '_modify', '_write', 'new', 'read', 'write', 'modify',"
    , "    'modifyImpl', 'newWithSelf',"
    , "    'pure_', 'bind_', 'map_', 'run', 'while_', 'for_', 'foreach',"
    , "    'mkSTFn1', 'mkSTFn2', 'mkSTFn3', 'mkSTFn4', 'mkSTFn5',"
    , "    'mkSTFn6', 'mkSTFn7', 'mkSTFn8', 'mkSTFn9', 'mkSTFn10',"
    , "    'runSTFn1', 'runSTFn2', 'runSTFn3', 'runSTFn4', 'runSTFn5',"
    , "    'runSTFn6', 'runSTFn7', 'runSTFn8', 'runSTFn9', 'runSTFn10',"
    , "    'mkFn0', 'mkFn2', 'mkFn3', 'mkFn4', 'mkFn5',"
    , "    'runFn0', 'runFn2', 'runFn3', 'runFn4', 'runFn5',"
    , "    'mkEffectFn1', 'mkEffectFn2', 'mkEffectFn3', 'mkEffectFn4', 'mkEffectFn5',"
    , "    'mkEffectFn6', 'mkEffectFn7', 'mkEffectFn8', 'mkEffectFn9', 'mkEffectFn10',"
    , "    'runEffectFn1', 'runEffectFn2', 'runEffectFn3', 'runEffectFn4', 'runEffectFn5',"
    , "    'runEffectFn6', 'runEffectFn7', 'runEffectFn8', 'runEffectFn9', 'runEffectFn10',"
    , "    'tailRec', 'Loop', 'Done',"
    , "    # Control.Monad.Asyncio"
    , "    'pureAsyncio', 'bindAsyncio', 'mapAsyncio', 'applyAsyncio',"
    , "    'runAsyncio', 'sleep', 'forkAsyncio', 'awaitTask', 'cancelTask',"
    , "    'parallelImpl', 'raceAsyncio', 'attemptAsyncio', 'throwErrorAsyncio',"
    , "    'catchErrorAsyncio', 'bracketAsyncio', 'liftEffectAsyncio',"
    , "]"
    , ""
    , "# Unit type"
    , "unit = None"
    , ""
    , "# Runtime error"
    , "def _runtime_fail(msg):"
    , "    raise RuntimeError(msg)"
    , ""
    , "# Unimplemented placeholder"
    , "def _unimplemented(msg):"
    , "    raise NotImplementedError(msg)"
    , ""
    , "# Lazy initialization wrapper (for mutually recursive bindings)"
    , "def _runtime_lazy(name, module_name, init):"
    , "    state = [0]  # 0=uninit, 1=initializing, 2=done"
    , "    val = [None]"
    , "    def thunk(*args):"
    , "        if state[0] == 2:"
    , "            return val[0]"
    , "        if state[0] == 1:"
    , "            raise RuntimeError(f'{name} was needed before finishing init (module {module_name})')"
    , "        state[0] = 1"
    , "        val[0] = init()"
    , "        state[0] = 2"
    , "        return val[0]"
    , "    return thunk"
    , ""
    , "# Boolean primitives (curried)"
    , "boolConj = lambda b1: lambda b2: b1 and b2"
    , "boolDisj = lambda b1: lambda b2: b1 or b2"
    , "boolNot = lambda b: not b"
    , ""
    , "# Integer primitives (curried)"
    , "intAdd = lambda x: lambda y: x + y"
    , "intSub = lambda x: lambda y: x - y"
    , "intMul = lambda x: lambda y: x * y"
    , "intDiv = lambda x: lambda y: x // y"
    , "intMod = lambda x: lambda y: x % y"
    , "intDegree = lambda x: min(abs(x), 2147483647)"
    , ""
    , "# Number primitives (curried)"
    , "numAdd = lambda x: lambda y: x + y"
    , "numSub = lambda x: lambda y: x - y"
    , "numMul = lambda x: lambda y: x * y"
    , "numDiv = lambda x: lambda y: x / y"
    , ""
    , "# Bounded"
    , "topInt = 2147483647"
    , "bottomInt = -2147483648"
    , "topChar = chr(65535)"
    , "bottomChar = chr(0)"
    , "topNumber = float('inf')"
    , "bottomNumber = float('-inf')"
    , ""
    , "# Eq primitives"
    , "eqBooleanImpl = lambda x: lambda y: x == y"
    , "eqIntImpl = lambda x: lambda y: x == y"
    , "eqNumberImpl = lambda x: lambda y: x == y"
    , "eqCharImpl = lambda x: lambda y: x == y"
    , "eqStringImpl = lambda x: lambda y: x == y"
    , "eqArrayImpl = lambda eq: lambda xs: lambda ys: len(xs) == len(ys) and all(eq(x)(y) for x, y in zip(xs, ys))"
    , ""
    , "# Ord primitives - take (lt, eq, gt, x, y) and return one of the constructors"
    , "def _unsafeCompareImpl(lt):"
    , "    def step2(eq):"
    , "        def step3(gt):"
    , "            def step4(x):"
    , "                def step5(y):"
    , "                    if x < y: return lt"
    , "                    elif x == y: return eq"
    , "                    else: return gt"
    , "                return step5"
    , "            return step4"
    , "        return step3"
    , "    return step2"
    , "ordBooleanImpl = _unsafeCompareImpl"
    , "ordIntImpl = _unsafeCompareImpl"
    , "ordNumberImpl = _unsafeCompareImpl"
    , "ordCharImpl = _unsafeCompareImpl"
    , "ordStringImpl = _unsafeCompareImpl"
    , ""
    , "# ordArrayImpl takes a comparison function that returns 0, 1, or -1"
    , "def ordArrayImpl(f):"
    , "    def step2(xs):"
    , "        def step3(ys):"
    , "            i = 0"
    , "            while i < len(xs) and i < len(ys):"
    , "                o = f(xs[i])(ys[i])"
    , "                if o != 0:"
    , "                    return o"
    , "                i += 1"
    , "            if len(xs) == len(ys): return 0"
    , "            elif len(xs) > len(ys): return -1"
    , "            else: return 1"
    , "        return step3"
    , "    return step2"
    , ""
    , "# Show primitives"
    , "showIntImpl = str"
    , "showNumberImpl = str"
    , "showCharImpl = lambda c: repr(c)"
    , "showStringImpl = repr"
    , "showArrayImpl = lambda show: lambda xs: '[' + ', '.join(show(x) for x in xs) + ']'"
    , ""
    , "# String primitives"
    , "concatString = lambda s1: lambda s2: s1 + s2"
    , ""
    , "# Array primitives"
    , "length = lambda xs: len(xs)"
    , "lengthImpl = len"
    , "# indexImpl takes (just, nothing, xs, i) - note xs comes before i!"
    , "indexImpl = lambda just, nothing, xs, i: just(xs[i]) if 0 <= i < len(xs) else nothing"
    , "concat = lambda xss: [x for xs in xss for x in xs]"
    , "# concatArray appends two arrays (curried): xs ++ ys"
    , "concatArray = lambda xs: lambda ys: xs + ys"
    , "rangeImpl = lambda start, end: list(range(start, end + 1)) if start <= end else list(range(start, end - 1, -1))"
    , "replicateImpl = lambda count, x: [x] * max(0, count)"
    , "reverse = lambda xs: xs[::-1]"
    , "filterImpl = lambda f, xs: [x for x in xs if f(x)]"
    , "# sortByImpl takes (cmp, toNum, xs) via runFn3"
    , "# cmp is the comparison function, toNum converts Ordering to number"
    , "def _sortByImpl(cmp, toNum, xs):"
    , "    import functools"
    , "    def compare_fn(a, b):"
    , "        return toNum(cmp(a)(b))"
    , "    return sorted(xs, key=functools.cmp_to_key(compare_fn))"
    , "sortByImpl = _sortByImpl"
    , "sliceImpl = lambda start, end, xs: xs[start:end]"
    , "zipWithImpl = lambda f, xs, ys: [f(x)(y) for x, y in zip(xs, ys)]"
    , "unsafeIndexImpl = lambda xs, i: xs[i]"
    , ""
    , "# Additional array functions (uncurried for runFnN)"
    , "# _insertAt takes (just, nothing, i, x, xs) via runFn5"
    , "def _insertAt(just, nothing, i, x, xs):"
    , "    if i < 0 or i > len(xs):"
    , "        return nothing"
    , "    result = xs[:i] + [x] + xs[i:]"
    , "    return just(result)"
    , ""
    , "# _deleteAt takes (just, nothing, i, xs) via runFn4"
    , "def _deleteAt(just, nothing, i, xs):"
    , "    if i < 0 or i >= len(xs):"
    , "        return nothing"
    , "    result = xs[:i] + xs[i+1:]"
    , "    return just(result)"
    , ""
    , "# _updateAt takes (just, nothing, i, x, xs) via runFn5"
    , "def _updateAt(just, nothing, i, x, xs):"
    , "    if i < 0 or i >= len(xs):"
    , "        return nothing"
    , "    result = xs[:i] + [x] + xs[i+1:]"
    , "    return just(result)"
    , ""
    , "# allImpl takes (p, xs) via runFn2"
    , "allImpl = lambda p, xs: all(p(x) for x in xs)"
    , ""
    , "# anyImpl takes (p, xs) via runFn2"
    , "anyImpl = lambda p, xs: any(p(x) for x in xs)"
    , ""
    , "# findIndexImpl takes (just, nothing, p, xs) via runFn4"
    , "def findIndexImpl(just, nothing, p, xs):"
    , "    for i, x in enumerate(xs):"
    , "        if p(x):"
    , "            return just(i)"
    , "    return nothing"
    , ""
    , "# findLastIndexImpl takes (just, nothing, p, xs) via runFn4"
    , "def findLastIndexImpl(just, nothing, p, xs):"
    , "    for i in range(len(xs) - 1, -1, -1):"
    , "        if p(xs[i]):"
    , "            return just(i)"
    , "    return nothing"
    , ""
    , "# findMapImpl takes (nothing, isJust, f, xs) via runFn4"
    , "def findMapImpl(nothing, isJust, f, xs):"
    , "    for x in xs:"
    , "        result = f(x)"
    , "        if isJust(result):"
    , "            return result"
    , "    return nothing"
    , ""
    , "# partitionImpl takes (p, xs) via runFn2"
    , "def partitionImpl(p, xs):"
    , "    yes = [x for x in xs if p(x)]"
    , "    no = [x for x in xs if not p(x)]"
    , "    return {'yes': yes, 'no': no}"
    , ""
    , "# unconsImpl takes (empty, next, xs) via runFn3"
    , "# empty is a thunked function that returns Nothing when called"
    , "def unconsImpl(empty, next, xs):"
    , "    if len(xs) == 0:"
    , "        return empty(None)  # Call the thunk with unit to get Nothing"
    , "    return next(xs[0])(xs[1:])"
    , ""
    , "# fromFoldableImpl takes (foldr, xs) via runFn2"
    , "def fromFoldableImpl(foldr, xs):"
    , "    return foldr(lambda x: lambda acc: [x] + acc)([])(xs)"
    , ""
    , "# scanlImpl takes (f, b, xs) via runFn3"
    , "def scanlImpl(f, b, xs):"
    , "    result = [b]"
    , "    acc = b"
    , "    for x in xs:"
    , "        acc = f(acc)(x)"
    , "        result.append(acc)"
    , "    return result"
    , ""
    , "# scanrImpl takes (f, b, xs) via runFn3"
    , "def scanrImpl(f, b, xs):"
    , "    result = [b]"
    , "    acc = b"
    , "    for x in reversed(xs):"
    , "        acc = f(x)(acc)"
    , "        result.insert(0, acc)"
    , "    return result"
    , ""
    , "# Data.Array.ST - mutable array operations"
    , "# STArray is just a Python list (which is mutable)"
    , "# These Impl functions are called via runSTFnN which handles thunk wrapping"
    , "# So the Impl functions should return values directly, not thunks"
    , ""
    , "# thawImpl takes (xs) via runSTFn1 - returns a copy"
    , "thawImpl = lambda xs: list(xs)"
    , "freezeImpl = lambda xs: list(xs)"
    , "unsafeThawImpl = thawImpl"
    , "unsafeFreezeImpl = freezeImpl"
    , "cloneImpl = thawImpl"
    , ""
    , "# peekImpl takes (just, nothing, i, xs) via runSTFn4"
    , "def peekImpl(just, nothing, i, xs):"
    , "    if 0 <= i < len(xs):"
    , "        return just(xs[i])"
    , "    return nothing"
    , ""
    , "# pokeImpl takes (i, x, xs) via runSTFn3"
    , "def pokeImpl(i, x, xs):"
    , "    if 0 <= i < len(xs):"
    , "        xs[i] = x"
    , "        return True"
    , "    return False"
    , ""
    , "# pushImpl takes (x, xs) via runSTFn2"
    , "def pushImpl(x, xs):"
    , "    xs.append(x)"
    , "    return len(xs)"
    , ""
    , "# pushAllImpl takes (ys, xs) via runSTFn2"
    , "def pushAllImpl(ys, xs):"
    , "    xs.extend(ys)"
    , "    return len(xs)"
    , ""
    , "# popImpl takes (just, nothing, xs) via runSTFn3"
    , "def popImpl(just, nothing, xs):"
    , "    if len(xs) > 0:"
    , "        return just(xs.pop())"
    , "    return nothing"
    , ""
    , "# shiftImpl takes (just, nothing, xs) via runSTFn3"
    , "def shiftImpl(just, nothing, xs):"
    , "    if len(xs) > 0:"
    , "        return just(xs.pop(0))"
    , "    return nothing"
    , ""
    , "# unshiftAllImpl takes (ys, xs) via runSTFn2"
    , "def unshiftAllImpl(ys, xs):"
    , "    for y in reversed(ys):"
    , "        xs.insert(0, y)"
    , "    return len(xs)"
    , ""
    , "# spliceImpl takes (start, deleteCount, items, xs) via runSTFn4"
    , "def spliceImpl(start, deleteCount, items, xs):"
    , "    deleted = xs[start:start+deleteCount]"
    , "    xs[start:start+deleteCount] = items"
    , "    return deleted"
    , ""
    , "# toAssocArrayImpl takes (xs) via runSTFn1"
    , "toAssocArrayImpl = lambda xs: [{'index': i, 'value': x} for i, x in enumerate(xs)]"
    , ""
    , "# lengthImpl for arrays - takes (xs)"
    , "lengthImpl = lambda xs: len(xs)"
    , ""
    , "# FunctorWithIndex"
    , "mapWithIndexArray = lambda f: lambda xs: [f(i)(x) for i, x in enumerate(xs)]"
    , ""
    , "# Traversable"
    , "def traverseArrayImpl(apply):"
    , "    def step2(map_):"
    , "        def step3(pure_):"
    , "            def step4(f):"
    , "                def step5(xs):"
    , "                    if len(xs) == 0:"
    , "                        return pure_([])"
    , "                    result = map_(lambda x: [x])(f(xs[0]))"
    , "                    for i in range(1, len(xs)):"
    , "                        result = apply(map_(lambda acc: lambda x: acc + [x])(result))(f(xs[i]))"
    , "                    return result"
    , "                return step5"
    , "            return step4"
    , "        return step3"
    , "    return step2"
    , ""
    , "# Foldable array"
    , "foldlArray = lambda f: lambda acc: lambda xs: (lambda a: (lambda i: a if i >= len(xs) else foldlArray(f)(f(a)(xs[i]))(xs[i+1:]))(0))(acc) if xs else acc"
    , "foldrArray = lambda f: lambda acc: lambda xs: f(xs[0])(foldrArray(f)(acc)(xs[1:])) if xs else acc"
    , ""
    , "# Map/Apply/Extend array"
    , "arrayMap = lambda f: lambda xs: [f(x) for x in xs]"
    , "arrayBind = lambda xs: lambda f: [y for x in xs for y in f(x)]"
    , "arrayApply = lambda fs: lambda xs: [f(x) for f in fs for x in xs]"
    , "# arrayExtend applies f to each suffix of the array"
    , "arrayExtend = lambda f: lambda xs: [f(xs[i:]) for i in range(len(xs))]"
    , ""
    , "# Data.Unfoldable1"
    , "# unfoldr1ArrayImpl :: (a -> Boolean) -> (a -> b) -> (a -> b) -> (a -> a) -> a -> Array b"
    , "# Signature: isNothing(maybe) -> fromJust(maybe) -> fst(tuple) -> snd(tuple) -> f -> init -> Array"
    , "def unfoldr1ArrayImpl(isNothing):"
    , "    def step2(fromJust):"
    , "        def step3(fst):"
    , "            def step4(snd):"
    , "                def step5(f):"
    , "                    def step6(init):"
    , "                        result = []"
    , "                        current = init"
    , "                        while True:"
    , "                            tuple_result = f(current)"
    , "                            result.append(fst(tuple_result))"
    , "                            maybe_next = snd(tuple_result)"
    , "                            if isNothing(maybe_next):"
    , "                                break"
    , "                            current = fromJust(maybe_next)"
    , "                        return result"
    , "                    return step6"
    , "                return step5"
    , "            return step4"
    , "        return step3"
    , "    return step2"
    , ""
    , "# Data.Unfoldable"
    , "# unfoldrArrayImpl :: (a -> Boolean) -> (a -> b) -> (a -> b) -> (a -> a) -> a -> Array b"
    , "# Signature: isNothing(maybe) -> fromJust(maybe) -> fst(tuple) -> snd(tuple) -> f -> init -> Array"
    , "def unfoldrArrayImpl(isNothing):"
    , "    def step2(fromJust):"
    , "        def step3(fst):"
    , "            def step4(snd):"
    , "                def step5(f):"
    , "                    def step6(init):"
    , "                        result = []"
    , "                        current = init"
    , "                        while True:"
    , "                            maybe_tuple = f(current)"
    , "                            if isNothing(maybe_tuple):"
    , "                                break"
    , "                            tuple_val = fromJust(maybe_tuple)"
    , "                            result.append(fst(tuple_val))"
    , "                            current = snd(tuple_val)"
    , "                        return result"
    , "                    return step6"
    , "                return step5"
    , "            return step4"
    , "        return step3"
    , "    return step2"
    , ""
    , "# Data.Array.NonEmpty.Internal"
    , "# foldl1Impl :: (a -> a -> a) -> NonEmptyArray a -> a"
    , "def _foldl1Impl(f, xs):"
    , "    if len(xs) == 0:"
    , "        raise RuntimeError('foldl1 on empty array')"
    , "    acc = xs[0]"
    , "    for i in range(1, len(xs)):"
    , "        acc = f(acc)(xs[i])"
    , "    return acc"
    , "foldl1Impl = lambda f, xs: _foldl1Impl(f, xs)"
    , ""
    , "# foldr1Impl :: (a -> a -> a) -> NonEmptyArray a -> a"
    , "def _foldr1Impl(f, xs):"
    , "    if len(xs) == 0:"
    , "        raise RuntimeError('foldr1 on empty array')"
    , "    acc = xs[-1]"
    , "    for i in range(len(xs) - 2, -1, -1):"
    , "        acc = f(xs[i])(acc)"
    , "    return acc"
    , "foldr1Impl = lambda f, xs: _foldr1Impl(f, xs)"
    , ""
    , "# traverse1Impl :: (Apply f) => (a -> a -> a) -> ((b -> c) -> b -> f c) -> (a -> f b) -> NonEmptyArray a -> f (NonEmptyArray b)"
    , "# Signature: apply -> map -> f -> xs -> f (NonEmptyArray)"
    , "def _traverse1Impl(apply, map_, f, xs):"
    , "    if len(xs) == 0:"
    , "        raise RuntimeError('traverse1 on empty array')"
    , "    # Start with the first element"
    , "    result = map_(lambda x: [x])(f(xs[0]))"
    , "    # Apply to the rest"
    , "    for i in range(1, len(xs)):"
    , "        result = apply(map_(lambda arr: lambda x: arr + [x])(result))(f(xs[i]))"
    , "    return result"
    , "traverse1Impl = lambda apply, map_, f, xs: _traverse1Impl(apply, map_, f, xs)"
    , ""
    , "# Data.Show.Generic"
    , "# intercalate joins an array of strings with a separator"
    , "intercalate = lambda sep: lambda xs: sep.join(xs)"
    , ""
    , "# Record access"
    , "unsafeGet = lambda key: lambda rec: rec[key]"
    , "unsafeSet = lambda key: lambda val: lambda rec: {**rec, key: val}"
    , "unsafeHas = lambda key: lambda rec: key in rec"
    , "unsafeDelete = lambda key: lambda rec: {k: v for k, v in rec.items() if k != key}"
    , ""
    , "# Unsafe coerce"
    , "unsafeCoerce = lambda x: x"
    , ""
    , "# Effect"
    , "# In PureScript, Effect a is represented as a thunk: () -> a"
    , "pureE = lambda a: lambda: a"
    , "def bindE(ma):"
    , "    def step2(f):"
    , "        def effect():"
    , "            a = ma()"
    , "            return f(a)()"
    , "        return effect"
    , "    return step2"
    , ""
    , "def untilE(cond):"
    , "    def effect():"
    , "        while not cond():"
    , "            pass"
    , "    return effect"
    , ""
    , "def whileE(cond):"
    , "    def step2(body):"
    , "        def effect():"
    , "            while cond():"
    , "                body()"
    , "        return effect"
    , "    return step2"
    , ""
    , "def forE(lo):"
    , "    def step2(hi):"
    , "        def step3(f):"
    , "            def effect():"
    , "                for i in range(lo, hi):"
    , "                    f(i)()"
    , "            return effect"
    , "        return step3"
    , "    return step2"
    , ""
    , "def foreachE(xs):"
    , "    def step2(f):"
    , "        def effect():"
    , "            for x in xs:"
    , "                f(x)()"
    , "        return effect"
    , "    return step2"
    , ""
    , "def unsafePerformEffect(eff):"
    , "    return eff()"
    , ""
    , "# Effect.Console"
    , "import sys"
    , "_console_timers = {}"
    , ""
    , "def log(s):"
    , "    def effect():"
    , "        print(s)"
    , "    return effect"
    , ""
    , "def warn(s):"
    , "    def effect():"
    , "        print(f'Warning: {s}', file=sys.stderr)"
    , "    return effect"
    , ""
    , "def error(s):"
    , "    def effect():"
    , "        print(f'Error: {s}', file=sys.stderr)"
    , "    return effect"
    , ""
    , "def info(s):"
    , "    def effect():"
    , "        print(f'Info: {s}')"
    , "    return effect"
    , ""
    , "def debug(s):"
    , "    def effect():"
    , "        print(f'Debug: {s}')"
    , "    return effect"
    , ""
    , "def group(s):"
    , "    def effect():"
    , "        print(f'▼ {s}')"
    , "    return effect"
    , ""
    , "def groupCollapsed(s):"
    , "    def effect():"
    , "        print(f'▶ {s}')"
    , "    return effect"
    , ""
    , "def groupEnd(s):"
    , "    def effect():"
    , "        pass  # No-op in terminal"
    , "    return effect"
    , ""
    , "import time as _time_module"
    , "def time(label):"
    , "    def effect():"
    , "        _console_timers[label] = _time_module.time()"
    , "    return effect"
    , ""
    , "def timeLog(label):"
    , "    def effect():"
    , "        if label in _console_timers:"
    , "            elapsed = (_time_module.time() - _console_timers[label]) * 1000"
    , "            print(f'{label}: {elapsed:.3f}ms')"
    , "    return effect"
    , ""
    , "def timeEnd(label):"
    , "    def effect():"
    , "        if label in _console_timers:"
    , "            elapsed = (_time_module.time() - _console_timers[label]) * 1000"
    , "            print(f'{label}: {elapsed:.3f}ms')"
    , "            del _console_timers[label]"
    , "    return effect"
    , ""
    , "def clear(s):"
    , "    def effect():"
    , "        print('\\033[2J\\033[H', end='')  # ANSI clear screen"
    , "    return effect"
    , ""
    , "# Effect.Ref"
    , "class Ref:"
    , "    def __init__(self, value):"
    , "        self.value = value"
    , ""
    , "def _new(val):"
    , "    def effect():"
    , "        return Ref(val)"
    , "    return effect"
    , ""
    , "def _read(ref):"
    , "    def effect():"
    , "        return ref.value"
    , "    return effect"
    , ""
    , "def _modify(f):"
    , "    def step2(ref):"
    , "        def effect():"
    , "            old = ref.value"
    , "            result = f(old)"
    , "            ref.value = result['state']"
    , "            return result['value']"
    , "        return effect"
    , "    return step2"
    , ""
    , "def _write(val):"
    , "    def step2(ref):"
    , "        def effect():"
    , "            ref.value = val"
    , "        return effect"
    , "    return step2"
    , ""
    , "# modifyImpl :: (a -> {state :: a, value :: b}) -> STRef h a -> ST h b"
    , "# The function returns {state: newState, value: returnValue}"
    , "def modifyImpl(f):"
    , "    def step2(ref):"
    , "        def effect():"
    , "            old = ref.value"
    , "            result = f(old)"
    , "            ref.value = result['state']"
    , "            return result['value']"
    , "        return effect"
    , "    return step2"
    , ""
    , "def newWithSelf(f):"
    , "    def effect():"
    , "        ref = Ref(None)"
    , "        ref.value = f(ref)"
    , "        return ref"
    , "    return effect"
    , ""
    , "# 'new' handles multiple cases:"
    , "# - Data.Array.ST.new: used as thunk in bind_(new), returns empty array"
    , "# - Control.Monad.ST.Internal.new(val): returns thunk that creates STRef"
    , "# - Effect.Ref.new: handled by its module which binds new = _new"
    , "_new_sentinel = object()"
    , "def new(val=_new_sentinel):"
    , "    if val is _new_sentinel:"
    , "        # No arg: Data.Array.ST.new - return empty array directly (acts as thunk result)"
    , "        return []"
    , "    else:"
    , "        # With arg: Control.Monad.ST.Internal.new - return thunked Ref"
    , "        return lambda: Ref(val)"
    , "read = _read"
    , "write = _write"
    , "modify = _modify"
    , ""
    , "# Control.Monad.ST.Internal (same semantics as Effect)"
    , "pure_ = pureE"
    , "bind_ = bindE"
    , "def map_(f):"
    , "    def step2(ma):"
    , "        def st():"
    , "            return f(ma())"
    , "        return st"
    , "    return step2"
    , ""
    , "run = lambda st: st()"
    , ""
    , "def while_(cond):"
    , "    def step2(body):"
    , "        def st():"
    , "            while cond():"
    , "                body()"
    , "        return st"
    , "    return step2"
    , ""
    , "def for_(lo):"
    , "    def step2(hi):"
    , "        def step3(f):"
    , "            def st():"
    , "                for i in range(lo, hi):"
    , "                    f(i)()"
    , "            return st"
    , "        return step3"
    , "    return step2"
    , ""
    , "def foreach(xs):"
    , "    def step2(f):"
    , "        def st():"
    , "            for x in xs:"
    , "                f(x)()"
    , "        return st"
    , "    return step2"
    , ""
    , "# Partial"
    , "def _crashWith(msg):"
    , "    raise RuntimeError(msg)"
    , ""
    , "# _unsafePartial: The Partial constraint is passed as an explicit argument"
    , "# We pass None as the 'evidence' since we're unsafely ignoring it"
    , "_unsafePartial = lambda f: f(None)"
    , ""
    , "# ST uncurried function helpers (same as Effect uncurried)"
    , "mkSTFn1 = lambda f: lambda a: f(a)"
    , "mkSTFn2 = lambda f: lambda a, b: f(a)(b)"
    , "mkSTFn3 = lambda f: lambda a, b, c: f(a)(b)(c)"
    , "mkSTFn4 = lambda f: lambda a, b, c, d: f(a)(b)(c)(d)"
    , "mkSTFn5 = lambda f: lambda a, b, c, d, e: f(a)(b)(c)(d)(e)"
    , "mkSTFn6 = lambda f: lambda a, b, c, d, e, g: f(a)(b)(c)(d)(e)(g)"
    , "mkSTFn7 = lambda f: lambda a, b, c, d, e, g, h: f(a)(b)(c)(d)(e)(g)(h)"
    , "mkSTFn8 = lambda f: lambda a, b, c, d, e, g, h, i: f(a)(b)(c)(d)(e)(g)(h)(i)"
    , "mkSTFn9 = lambda f: lambda a, b, c, d, e, g, h, i, j: f(a)(b)(c)(d)(e)(g)(h)(i)(j)"
    , "mkSTFn10 = lambda f: lambda a, b, c, d, e, g, h, i, j, k: f(a)(b)(c)(d)(e)(g)(h)(i)(j)(k)"
    , ""
    , "# runSTFnN: like runFnN but wraps result in an ST thunk"
    , "runSTFn1 = lambda f: lambda a: lambda: f(a)"
    , "runSTFn2 = lambda f: lambda a: lambda b: lambda: f(a, b)"
    , "runSTFn3 = lambda f: lambda a: lambda b: lambda c: lambda: f(a, b, c)"
    , "runSTFn4 = lambda f: lambda a: lambda b: lambda c: lambda d: lambda: f(a, b, c, d)"
    , "runSTFn5 = lambda f: lambda a: lambda b: lambda c: lambda d: lambda e: lambda: f(a, b, c, d, e)"
    , "runSTFn6 = lambda f: lambda a: lambda b: lambda c: lambda d: lambda e: lambda g: lambda: f(a, b, c, d, e, g)"
    , "runSTFn7 = lambda f: lambda a: lambda b: lambda c: lambda d: lambda e: lambda g: lambda h: lambda: f(a, b, c, d, e, g, h)"
    , "runSTFn8 = lambda f: lambda a: lambda b: lambda c: lambda d: lambda e: lambda g: lambda h: lambda i: lambda: f(a, b, c, d, e, g, h, i)"
    , "runSTFn9 = lambda f: lambda a: lambda b: lambda c: lambda d: lambda e: lambda g: lambda h: lambda i: lambda j: lambda: f(a, b, c, d, e, g, h, i, j)"
    , "runSTFn10 = lambda f: lambda a: lambda b: lambda c: lambda d: lambda e: lambda g: lambda h: lambda i: lambda j: lambda k: lambda: f(a, b, c, d, e, g, h, i, j, k)"
    , ""
    , "# uncurried function helpers"
    , "mkFn0 = lambda f: lambda: f"
    , "mkFn2 = lambda f: lambda a, b: f(a)(b)"
    , "mkFn3 = lambda f: lambda a, b, c: f(a)(b)(c)"
    , "mkFn4 = lambda f: lambda a, b, c, d: f(a)(b)(c)(d)"
    , "mkFn5 = lambda f: lambda a, b, c, d, e: f(a)(b)(c)(d)(e)"
    , "runFn0 = lambda f: f()"
    , "runFn2 = lambda f: lambda a: lambda b: f(a, b)"
    , "runFn3 = lambda f: lambda a: lambda b: lambda c: f(a, b, c)"
    , "runFn4 = lambda f: lambda a: lambda b: lambda c: lambda d: f(a, b, c, d)"
    , "runFn5 = lambda f: lambda a: lambda b: lambda c: lambda d: lambda e: f(a, b, c, d, e)"
    , ""
    , "# Effect.Uncurried"
    , "# mkEffectFnN wraps a curried effectful function into an uncurried one"
    , "# The result is a function that takes N args and returns an Effect (thunk)"
    , "mkEffectFn1 = lambda f: lambda a: f(a)"
    , "mkEffectFn2 = lambda f: lambda a, b: f(a)(b)"
    , "mkEffectFn3 = lambda f: lambda a, b, c: f(a)(b)(c)"
    , "mkEffectFn4 = lambda f: lambda a, b, c, d: f(a)(b)(c)(d)"
    , "mkEffectFn5 = lambda f: lambda a, b, c, d, e: f(a)(b)(c)(d)(e)"
    , "mkEffectFn6 = lambda f: lambda a, b, c, d, e, g: f(a)(b)(c)(d)(e)(g)"
    , "mkEffectFn7 = lambda f: lambda a, b, c, d, e, g, h: f(a)(b)(c)(d)(e)(g)(h)"
    , "mkEffectFn8 = lambda f: lambda a, b, c, d, e, g, h, i: f(a)(b)(c)(d)(e)(g)(h)(i)"
    , "mkEffectFn9 = lambda f: lambda a, b, c, d, e, g, h, i, j: f(a)(b)(c)(d)(e)(g)(h)(i)(j)"
    , "mkEffectFn10 = lambda f: lambda a, b, c, d, e, g, h, i, j, k: f(a)(b)(c)(d)(e)(g)(h)(i)(j)(k)"
    , ""
    , "# runEffectFnN converts an uncurried effectful function back to curried form"
    , "runEffectFn1 = lambda f: lambda a: lambda: f(a)()"
    , "runEffectFn2 = lambda f: lambda a: lambda b: lambda: f(a, b)()"
    , "runEffectFn3 = lambda f: lambda a: lambda b: lambda c: lambda: f(a, b, c)()"
    , "runEffectFn4 = lambda f: lambda a: lambda b: lambda c: lambda d: lambda: f(a, b, c, d)()"
    , "runEffectFn5 = lambda f: lambda a: lambda b: lambda c: lambda d: lambda e: lambda: f(a, b, c, d, e)()"
    , "runEffectFn6 = lambda f: lambda a: lambda b: lambda c: lambda d: lambda e: lambda g: lambda: f(a, b, c, d, e, g)()"
    , "runEffectFn7 = lambda f: lambda a: lambda b: lambda c: lambda d: lambda e: lambda g: lambda h: lambda: f(a, b, c, d, e, g, h)()"
    , "runEffectFn8 = lambda f: lambda a: lambda b: lambda c: lambda d: lambda e: lambda g: lambda h: lambda i: lambda: f(a, b, c, d, e, g, h, i)()"
    , "runEffectFn9 = lambda f: lambda a: lambda b: lambda c: lambda d: lambda e: lambda g: lambda h: lambda i: lambda j: lambda: f(a, b, c, d, e, g, h, i, j)()"
    , "runEffectFn10 = lambda f: lambda a: lambda b: lambda c: lambda d: lambda e: lambda g: lambda h: lambda i: lambda j: lambda k: lambda: f(a, b, c, d, e, g, h, i, j, k)()"
    , ""
    , "# Control.Monad.Rec.Class"
    , "# tailRec :: forall a b. (a -> Step a b) -> a -> b"
    , "# Step is represented as ('Loop', a) or ('Done', b)"
    , "# This is the KEY function for stack-safe recursion!"
    , "def tailRec(f):"
    , "    def run(initial):"
    , "        result = f(initial)"
    , "        while result[0] == 'Loop':"
    , "            result = f(result[1])"
    , "        # result[0] == 'Done'"
    , "        return result[1]"
    , "    return run"
    , ""
    , "# Loop and Done constructors"
    , "Loop = lambda a: ('Loop', a)"
    , "Done = lambda a: ('Done', a)"
    , ""
    , "# ============================================================================"
    , "# Control.Monad.Asyncio - Native Python async monad"
    , "# ============================================================================"
    , "import asyncio"
    , ""
    , "# Asyncio a = () -> Coroutine[Any, Any, a]"
    , "# A thunk that returns a coroutine (preserves laziness)"
    , ""
    , "# Pure: lift a value into Asyncio"
    , "def pureAsyncio(a):"
    , "    async def coro():"
    , "        return a"
    , "    return lambda: coro()"
    , ""
    , "# Bind: sequence Asyncio computations"
    , "def bindAsyncio(asyncio_a):"
    , "    def bind_k(f):"
    , "        async def coro():"
    , "            a = await asyncio_a()"
    , "            asyncio_b = f(a)"
    , "            return await asyncio_b()"
    , "        return lambda: coro()"
    , "    return bind_k"
    , ""
    , "# Map: transform the result"
    , "def mapAsyncio(f):"
    , "    def mapper(asyncio_a):"
    , "        async def coro():"
    , "            a = await asyncio_a()"
    , "            return f(a)"
    , "        return lambda: coro()"
    , "    return mapper"
    , ""
    , "# Apply: apply a wrapped function"
    , "def applyAsyncio(asyncio_f):"
    , "    def applier(asyncio_a):"
    , "        async def coro():"
    , "            f = await asyncio_f()"
    , "            a = await asyncio_a()"
    , "            return f(a)"
    , "        return lambda: coro()"
    , "    return applier"
    , ""
    , "# Run: execute async computation (blocking)"
    , "def runAsyncio(asyncio_a):"
    , "    def effect():"
    , "        return asyncio.run(asyncio_a())"
    , "    return effect"
    , ""
    , "# Sleep: pause for given milliseconds"
    , "def sleep(ms):"
    , "    async def coro():"
    , "        await asyncio.sleep(ms / 1000.0)"
    , "        return None"
    , "    return lambda: coro()"
    , ""
    , "# Fork: run async computation in background, return Task handle"
    , "def forkAsyncio(asyncio_a):"
    , "    async def coro():"
    , "        task = asyncio.create_task(asyncio_a())"
    , "        return task"
    , "    return lambda: coro()"
    , ""
    , "# Await: wait for a Task to complete"
    , "def awaitTask(task):"
    , "    async def coro():"
    , "        return await task"
    , "    return lambda: coro()"
    , ""
    , "# Cancel: cancel a running Task"
    , "def cancelTask(task):"
    , "    async def coro():"
    , "        task.cancel()"
    , "        try:"
    , "            await task"
    , "        except asyncio.CancelledError:"
    , "            pass"
    , "        return None"
    , "    return lambda: coro()"
    , ""
    , "# Parallel: run multiple async computations concurrently"
    , "def parallelImpl(asyncios):"
    , "    async def coro():"
    , "        coros = [a() for a in asyncios]"
    , "        return list(await asyncio.gather(*coros))"
    , "    return lambda: coro()"
    , ""
    , "# Race: run two computations, return first to complete, cancel other"
    , "def raceAsyncio(asyncio_a):"
    , "    def racer(asyncio_b):"
    , "        async def coro():"
    , "            task_a = asyncio.create_task(asyncio_a())"
    , "            task_b = asyncio.create_task(asyncio_b())"
    , "            done, pending = await asyncio.wait("
    , "                [task_a, task_b],"
    , "                return_when=asyncio.FIRST_COMPLETED"
    , "            )"
    , "            for task in pending:"
    , "                task.cancel()"
    , "            return done.pop().result()"
    , "        return lambda: coro()"
    , "    return racer"
    , ""
    , "# Attempt: catch errors and return Either"
    , "def attemptAsyncio(asyncio_a):"
    , "    async def coro():"
    , "        try:"
    , "            result = await asyncio_a()"
    , "            return ('Right', result)"
    , "        except Exception as e:"
    , "            return ('Left', str(e))"
    , "    return lambda: coro()"
    , ""
    , "# ThrowError: raise an error in async context"
    , "def throwErrorAsyncio(msg):"
    , "    async def coro():"
    , "        raise Exception(msg)"
    , "    return lambda: coro()"
    , ""
    , "# CatchError: handle errors with recovery function"
    , "def catchErrorAsyncio(asyncio_a):"
    , "    def catcher(handler):"
    , "        async def coro():"
    , "            try:"
    , "                return await asyncio_a()"
    , "            except Exception as e:"
    , "                recovery = handler(str(e))"
    , "                return await recovery()"
    , "        return lambda: coro()"
    , "    return catcher"
    , ""
    , "# Bracket: acquire/use/release with guaranteed cleanup"
    , "def bracketAsyncio(acquire):"
    , "    def with_release(release):"
    , "        def use_resource(use):"
    , "            async def coro():"
    , "                resource = await acquire()"
    , "                try:"
    , "                    result = await use(resource)()"
    , "                    return result"
    , "                finally:"
    , "                    await release(resource)()"
    , "            return lambda: coro()"
    , "        return use_resource"
    , "    return with_release"
    , ""
    , "# LiftEffect: run synchronous Effect in async context"
    , "def liftEffectAsyncio(effect):"
    , "    async def coro():"
    , "        return effect()"
    , "    return lambda: coro()"
    , ""
    ]

-- | Simple expression printer (temporary - should use Printer module properly)
printExpr :: Py.PyExpr -> String
printExpr = case _ of
  Py.PyVar (Py.PyIdent s) -> s
  Py.PyLitInt n -> show n
  Py.PyLitNumber n -> show n
  Py.PyLitString s -> "\"" <> escapeString s <> "\""
  Py.PyLitBool true -> "True"
  Py.PyLitBool false -> "False"
  Py.PyLitNone -> "None"
  Py.PyLitArray items -> "[" <> String.joinWith ", " (map printExpr items) <> "]"
  Py.PyLitObject fields ->
    "{" <> String.joinWith ", " (map printField fields) <> "}"
    where
    printField (Tuple k v) = "\"" <> k <> "\": " <> printExpr v
  Py.PyLambda args body ->
    "(lambda " <> String.joinWith ", " (map (\(Py.PyIdent s) -> s) args) <> ": " <> printExpr body <> ")"
  Py.PyApp fn args ->
    "(" <> printExpr fn <> ")(" <> String.joinWith ", " (map printExpr args) <> ")"
  Py.PyCall fn args ->
    printExpr fn <> "(" <> String.joinWith ", " (map printExpr args) <> ")"
  Py.PyAccess expr field ->
    printExpr expr <> "." <> field
  Py.PyIndex expr idx ->
    printExpr expr <> "[" <> printExpr idx <> "]"
  Py.PyBinOp op left right ->
    "(" <> printExpr left <> " " <> op <> " " <> printExpr right <> ")"
  Py.PyUnaryOp op expr ->
    "(" <> op <> " " <> printExpr expr <> ")"
  Py.PyTernary cond then_ else_ ->
    "(" <> printExpr then_ <> " if " <> printExpr cond <> " else " <> printExpr else_ <> ")"
  Py.PyTuple items ->
    -- Python requires trailing comma for single-element tuples
    case items of
      [] -> "()"
      [item] -> "(" <> printExpr item <> ",)"
      _ -> "(" <> String.joinWith ", " (map printExpr items) <> ")"
  Py.PyWalrus (Py.PyIdent name) expr ->
    "(" <> name <> " := " <> printExpr expr <> ")"

-- | Print a statement with given indentation
printStmt :: Int -> Py.PyStmt -> String
printStmt indent stmt =
  let ind = String.joinWith "" (Array.replicate indent "    ")
  in ind <> printStmtInner indent stmt

-- | Print statement content (without leading indent)
printStmtInner :: Int -> Py.PyStmt -> String
printStmtInner indent = case _ of
  Py.PyAssign (Py.PyIdent name) expr ->
    name <> " = " <> printExpr expr
  Py.PyMultiAssign names exprs ->
    String.joinWith ", " (map (\(Py.PyIdent n) -> n) names) <>
    " = " <>
    String.joinWith ", " (map printExpr exprs)
  Py.PyExprStmt expr ->
    printExpr expr
  Py.PyReturn expr ->
    "return " <> printExpr expr
  Py.PyReturnNothing ->
    "return"
  Py.PyIf cond thenStmts elseStmts ->
    "if " <> printExpr cond <> ":\n" <>
    printBlock (indent + 1) thenStmts <>
    case elseStmts of
      Nothing -> ""
      Just stmts -> "\n" <> String.joinWith "" (Array.replicate indent "    ") <> "else:\n" <>
        printBlock (indent + 1) stmts
  Py.PyWhile cond body ->
    "while " <> printExpr cond <> ":\n" <>
    printBlock (indent + 1) body
  Py.PyFor (Py.PyIdent var) iter body ->
    "for " <> var <> " in " <> printExpr iter <> ":\n" <>
    printBlock (indent + 1) body
  Py.PyDef (Py.PyIdent name) args body ->
    "def " <> name <> "(" <> String.joinWith ", " (map (\(Py.PyIdent a) -> a) args) <> "):\n" <>
    printBlock (indent + 1) body
  Py.PyClass (Py.PyIdent name) parent body ->
    "class " <> name <>
    (case parent of
      Nothing -> ""
      Just (Py.PyIdent p) -> "(" <> p <> ")") <>
    ":\n" <> printBlock (indent + 1) body
  Py.PyImport mod ->
    "import " <> mod
  Py.PyFromImport mod names ->
    "from " <> mod <> " import " <> String.joinWith ", " names
  Py.PyPass ->
    "pass"
  Py.PyContinue ->
    "continue"
  Py.PyBreak ->
    "break"
  Py.PyComment text ->
    "# " <> text

-- | Print a block of statements
printBlock :: Int -> Array Py.PyStmt -> String
printBlock indent stmts =
  case stmts of
    [] -> String.joinWith "" (Array.replicate indent "    ") <> "pass"
    _ -> String.joinWith "\n" (map (printStmt indent) stmts)

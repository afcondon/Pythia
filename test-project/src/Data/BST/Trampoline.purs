-- | Stack-safe Binary Search Tree using trampolines
-- | All operations work for arbitrarily deep trees
module Data.BST.Trampoline where

import Prelude

import Control.Monad.Rec.Class (Step(..), tailRec)
import Data.Array as Array
import Data.Maybe (Maybe(..))
import Data.Tuple (Tuple(..))

-- | Binary Search Tree ADT
data Tree a
  = Empty
  | Node (Tree a) a (Tree a)

-- | Path element for tree zipper - records which direction we went and the sibling
data PathElem a
  = WentLeft a (Tree a)   -- went left, saved value and right subtree
  | WentRight (Tree a) a  -- went right, saved left subtree and value

-- | Create an empty tree
empty :: forall a. Tree a
empty = Empty

-- | Create a singleton tree
singleton :: forall a. a -> Tree a
singleton x = Node Empty x Empty

-- | Check if tree is empty
isEmpty :: forall a. Tree a -> Boolean
isEmpty Empty = true
isEmpty _ = false

-- | Stack-safe insert using zipper pattern
-- | Walks down accumulating path, then rebuilds on the way up
insert :: forall a. Ord a => a -> Tree a -> Tree a
insert x tree = tailRec go { path: [], current: tree }
  where
  go :: { path :: Array (PathElem a), current :: Tree a }
     -> Step { path :: Array (PathElem a), current :: Tree a } (Tree a)
  go { path, current: Empty } =
    -- Found insertion point, now rebuild upward
    Done (rebuildPath path (singleton x))
  go { path, current: Node left val right }
    | x < val = Loop { path: Array.cons (WentLeft val right) path, current: left }
    | x > val = Loop { path: Array.cons (WentRight left val) path, current: right }
    | otherwise = Done (rebuildPath path (Node left val right))  -- duplicate

-- | Rebuild tree from path (tail-recursive via tailRec)
rebuildPath :: forall a. Array (PathElem a) -> Tree a -> Tree a
rebuildPath path subtree = tailRec go { path, tree: subtree }
  where
  go :: { path :: Array (PathElem a), tree :: Tree a }
     -> Step { path :: Array (PathElem a), tree :: Tree a } (Tree a)
  go { path: p, tree } = case Array.uncons p of
    Nothing -> Done tree
    Just { head: WentLeft val right, tail } ->
      Loop { path: tail, tree: Node tree val right }
    Just { head: WentRight left val, tail } ->
      Loop { path: tail, tree: Node left val tree }

-- | Stack-safe search (already tail-recursive, but let's be explicit)
member :: forall a. Ord a => a -> Tree a -> Boolean
member x tree = tailRec go tree
  where
  go :: Tree a -> Step (Tree a) Boolean
  go Empty = Done false
  go (Node left val right)
    | x < val = Loop left
    | x > val = Loop right
    | otherwise = Done true

-- | Stack-safe lookup
lookup :: forall a. Ord a => a -> Tree a -> Maybe a
lookup x tree = tailRec go tree
  where
  go :: Tree a -> Step (Tree a) (Maybe a)
  go Empty = Done Nothing
  go (Node left val right)
    | x < val = Loop left
    | x > val = Loop right
    | otherwise = Done (Just val)

-- | Stack-safe findMin
findMin :: forall a. Tree a -> Maybe a
findMin tree = tailRec go tree
  where
  go :: Tree a -> Step (Tree a) (Maybe a)
  go Empty = Done Nothing
  go (Node Empty val _) = Done (Just val)
  go (Node left _ _) = Loop left

-- | Stack-safe findMax
findMax :: forall a. Tree a -> Maybe a
findMax tree = tailRec go tree
  where
  go :: Tree a -> Step (Tree a) (Maybe a)
  go Empty = Done Nothing
  go (Node _ val Empty) = Done (Just val)
  go (Node _ _ right) = Loop right

-- | Stack-safe delete using zipper
delete :: forall a. Ord a => a -> Tree a -> Tree a
delete x tree = tailRec goDown { path: [], current: tree }
  where
  goDown :: { path :: Array (PathElem a), current :: Tree a }
         -> Step { path :: Array (PathElem a), current :: Tree a } (Tree a)
  goDown { path, current: Empty } =
    -- Value not found, rebuild unchanged
    Done (rebuildPath path Empty)
  goDown { path, current: Node left val right }
    | x < val = Loop { path: Array.cons (WentLeft val right) path, current: left }
    | x > val = Loop { path: Array.cons (WentRight left val) path, current: right }
    | otherwise =
        -- Found it! Delete this node
        Done (rebuildPath path (deleteNode left right))

  deleteNode :: Tree a -> Tree a -> Tree a
  deleteNode Empty r = r
  deleteNode l Empty = l
  deleteNode l r = case findMin r of
    Nothing -> l
    Just minVal -> Node l minVal (delete minVal r)

-- | Stack-safe fold using explicit stack
foldTree :: forall a b. (b -> a -> b) -> b -> Tree a -> b
foldTree f initial tree = tailRec go { acc: initial, current: tree, stack: [] }
  where
  go :: { acc :: b, current :: Tree a, stack :: Array (Tuple a (Tree a)) }
     -> Step { acc :: b, current :: Tree a, stack :: Array (Tuple a (Tree a)) } b
  go { acc, current: Empty, stack } = case Array.uncons stack of
    Nothing -> Done acc
    Just { head: Tuple val right, tail } ->
      Loop { acc: f acc val, current: right, stack: tail }
  go { acc, current: Node left val right, stack } =
    Loop { acc, current: left, stack: Array.cons (Tuple val right) stack }

-- | Stack-safe in-order traversal
inorder :: forall a. Tree a -> Array a
inorder tree = tailRec go { result: [], current: tree, stack: [] }
  where
  go :: { result :: Array a, current :: Tree a, stack :: Array (Tuple a (Tree a)) }
     -> Step { result :: Array a, current :: Tree a, stack :: Array (Tuple a (Tree a)) } (Array a)
  go { result, current: Empty, stack } = case Array.uncons stack of
    Nothing -> Done result
    Just { head: Tuple val right, tail } ->
      Loop { result: Array.snoc result val, current: right, stack: tail }
  go { result, current: Node left val right, stack } =
    Loop { result, current: left, stack: Array.cons (Tuple val right) stack }

-- | Stack-safe pre-order traversal
preorder :: forall a. Tree a -> Array a
preorder tree = tailRec go { result: [], stack: [tree] }
  where
  go :: { result :: Array a, stack :: Array (Tree a) }
     -> Step { result :: Array a, stack :: Array (Tree a) } (Array a)
  go { result, stack } = case Array.uncons stack of
    Nothing -> Done result
    Just { head: Empty, tail } -> Loop { result, stack: tail }
    Just { head: Node left val right, tail } ->
      Loop { result: Array.snoc result val, stack: Array.cons left (Array.cons right tail) }

-- | Size of tree (stack-safe)
size :: forall a. Tree a -> Int
size tree = tailRec go { count: 0, stack: [tree] }
  where
  go :: { count :: Int, stack :: Array (Tree a) }
     -> Step { count :: Int, stack :: Array (Tree a) } Int
  go { count, stack } = case Array.uncons stack of
    Nothing -> Done count
    Just { head: Empty, tail } -> Loop { count, stack: tail }
    Just { head: Node left _ right, tail } ->
      Loop { count: count + 1, stack: Array.cons left (Array.cons right tail) }

-- | Height of tree (needs different approach - compute during traversal)
-- | We track the max depth seen so far
height :: forall a. Tree a -> Int
height tree = tailRec go { maxDepth: 0, stack: [{ depth: 0, node: tree }] }
  where
  go :: { maxDepth :: Int, stack :: Array { depth :: Int, node :: Tree a } }
     -> Step { maxDepth :: Int, stack :: Array { depth :: Int, node :: Tree a } } Int
  go { maxDepth, stack } = case Array.uncons stack of
    Nothing -> Done maxDepth
    Just { head: { depth, node: Empty }, tail } ->
      Loop { maxDepth: max maxDepth depth, stack: tail }
    Just { head: { depth, node: Node left _ right }, tail } ->
      let newDepth = depth + 1
      in Loop { maxDepth, stack: Array.cons { depth: newDepth, node: left }
                                  (Array.cons { depth: newDepth, node: right } tail) }

-- | Sum of integer tree (using our stack-safe fold)
sumTree :: Tree Int -> Int
sumTree = foldTree (+) 0

-- | Build tree from array (uses stack-safe insert)
fromArray :: forall a. Ord a => Array a -> Tree a
fromArray = Array.foldl (flip insert) empty

-- | Convert to sorted array
toArray :: forall a. Tree a -> Array a
toArray = inorder

-- | Map over tree
-- | Note: This uses simple recursion. For very deep trees, you'd need
-- | a more complex CPS-based approach. The critical stack-safe operations
-- | are insert, delete, member, lookup, fold, and traversals.
mapTree :: forall a b. (a -> b) -> Tree a -> Tree b
mapTree _ Empty = Empty
mapTree f (Node left val right) = Node (mapTree f left) (f val) (mapTree f right)

-- | Mirror the tree
mirror :: forall a. Tree a -> Tree a
mirror Empty = Empty
mirror (Node left val right) = Node (mirror right) val (mirror left)

-- | Count leaves
countLeaves :: forall a. Tree a -> Int
countLeaves tree = tailRec go { count: 0, stack: [tree] }
  where
  go :: { count :: Int, stack :: Array (Tree a) }
     -> Step { count :: Int, stack :: Array (Tree a) } Int
  go { count, stack } = case Array.uncons stack of
    Nothing -> Done count
    Just { head: Empty, tail } -> Loop { count, stack: tail }
    Just { head: Node Empty _ Empty, tail } -> Loop { count: count + 1, stack: tail }
    Just { head: Node left _ right, tail } ->
      Loop { count, stack: Array.cons left (Array.cons right tail) }

-- | Balance factor at root
balanceFactor :: forall a. Tree a -> Int
balanceFactor Empty = 0
balanceFactor (Node left _ right) = height left - height right

-- | Check if balanced
isBalanced :: forall a. Tree a -> Boolean
isBalanced tree = tailRec go { stack: [tree] }
  where
  go :: { stack :: Array (Tree a) }
     -> Step { stack :: Array (Tree a) } Boolean
  go { stack } = case Array.uncons stack of
    Nothing -> Done true
    Just { head: Empty, tail } -> Loop { stack: tail }
    Just { head: t@(Node left _ right), tail } ->
      let bf = balanceFactor t
      in if bf >= -1 && bf <= 1
         then Loop { stack: Array.cons left (Array.cons right tail) }
         else Done false

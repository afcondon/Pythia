-- | Binary Search Tree implementation
-- | Demonstrates ADTs, pattern matching, TCO, and higher-order functions
module Data.BST where

import Prelude

import Data.Array as Array
import Data.Maybe (Maybe(..))
import Data.Tuple (Tuple(..))

-- | Binary Search Tree ADT
data Tree a
  = Empty
  | Node (Tree a) a (Tree a)

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

-- | Insert a value into the tree
insert :: forall a. Ord a => a -> Tree a -> Tree a
insert x Empty = singleton x
insert x (Node left val right)
  | x < val = Node (insert x left) val right
  | x > val = Node left val (insert x right)
  | otherwise = Node left val right  -- duplicate, keep existing

-- | Search for a value in the tree
member :: forall a. Ord a => a -> Tree a -> Boolean
member _ Empty = false
member x (Node left val right)
  | x < val = member x left
  | x > val = member x right
  | otherwise = true

-- | Find a value in the tree
lookup :: forall a. Ord a => a -> Tree a -> Maybe a
lookup _ Empty = Nothing
lookup x (Node left val right)
  | x < val = lookup x left
  | x > val = lookup x right
  | otherwise = Just val

-- | Find the minimum value
findMin :: forall a. Tree a -> Maybe a
findMin Empty = Nothing
findMin (Node Empty val _) = Just val
findMin (Node left _ _) = findMin left

-- | Find the maximum value
findMax :: forall a. Tree a -> Maybe a
findMax Empty = Nothing
findMax (Node _ val Empty) = Just val
findMax (Node _ _ right) = findMax right

-- | Delete a value from the tree
delete :: forall a. Ord a => a -> Tree a -> Tree a
delete _ Empty = Empty
delete x (Node left val right)
  | x < val = Node (delete x left) val right
  | x > val = Node left val (delete x right)
  | otherwise = deleteNode left right
  where
  deleteNode :: Tree a -> Tree a -> Tree a
  deleteNode Empty r = r
  deleteNode l Empty = l
  deleteNode l r = case findMin r of
    Nothing -> l  -- shouldn't happen
    Just minVal -> Node l minVal (delete minVal r)

-- | Count the number of nodes
size :: forall a. Tree a -> Int
size Empty = 0
size (Node left _ right) = 1 + size left + size right

-- | Calculate the height of the tree
height :: forall a. Tree a -> Int
height Empty = 0
height (Node left _ right) = 1 + max (height left) (height right)

-- | In-order traversal (sorted order)
inorder :: forall a. Tree a -> Array a
inorder Empty = []
inorder (Node left val right) = inorder left <> [val] <> inorder right

-- | Pre-order traversal (root first)
preorder :: forall a. Tree a -> Array a
preorder Empty = []
preorder (Node left val right) = [val] <> preorder left <> preorder right

-- | Post-order traversal (root last)
postorder :: forall a. Tree a -> Array a
postorder Empty = []
postorder (Node left val right) = postorder left <> postorder right <> [val]

-- | Fold over the tree (in-order)
foldTree :: forall a b. (b -> a -> b) -> b -> Tree a -> b
foldTree _ acc Empty = acc
foldTree f acc (Node left val right) =
  let leftAcc = foldTree f acc left
      midAcc = f leftAcc val
  in foldTree f midAcc right

-- | Map a function over the tree
mapTree :: forall a b. (a -> b) -> Tree a -> Tree b
mapTree _ Empty = Empty
mapTree f (Node left val right) = Node (mapTree f left) (f val) (mapTree f right)

-- | Sum all values in an integer tree
sumTree :: Tree Int -> Int
sumTree = foldTree (+) 0

-- | Build a tree from an array
fromArray :: forall a. Ord a => Array a -> Tree a
fromArray = Array.foldl (flip insert) empty

-- | Convert tree to sorted array
toArray :: forall a. Tree a -> Array a
toArray = inorder

-- | Check if the tree satisfies the BST property
isValidBST :: forall a. Ord a => Tree a -> Boolean
isValidBST tree = isSorted (inorder tree)
  where
  isSorted :: Array a -> Boolean
  isSorted arr = case Array.uncons arr of
    Nothing -> true
    Just { head: _, tail } -> case Array.uncons tail of
      Nothing -> true
      Just { head: next, tail: rest } ->
        case Array.uncons arr of
          Just { head: x, tail: _ } -> x <= next && isSorted (Array.cons next rest)
          Nothing -> true

-- | Balance check - returns the balance factor at root
balanceFactor :: forall a. Tree a -> Int
balanceFactor Empty = 0
balanceFactor (Node left _ right) = height left - height right

-- | Check if tree is balanced (AVL property: |balance| <= 1 at all nodes)
isBalanced :: forall a. Tree a -> Boolean
isBalanced Empty = true
isBalanced t@(Node left _ right) =
  let bf = balanceFactor t
  in bf >= -1 && bf <= 1 && isBalanced left && isBalanced right

-- | Get all values at a specific depth
atDepth :: forall a. Int -> Tree a -> Array a
atDepth _ Empty = []
atDepth 0 (Node _ val _) = [val]
atDepth n (Node left _ right) = atDepth (n - 1) left <> atDepth (n - 1) right

-- | Level-order traversal (breadth-first)
levelOrder :: forall a. Tree a -> Array a
levelOrder tree = go [tree]
  where
  go :: Array (Tree a) -> Array a
  go queue = case Array.uncons queue of
    Nothing -> []
    Just { head: Empty, tail } -> go tail
    Just { head: Node left val right, tail } ->
      [val] <> go (tail <> [left, right])

-- | Count leaves (nodes with no children)
countLeaves :: forall a. Tree a -> Int
countLeaves Empty = 0
countLeaves (Node Empty _ Empty) = 1
countLeaves (Node left _ right) = countLeaves left + countLeaves right

-- | Mirror the tree (swap left and right)
mirror :: forall a. Tree a -> Tree a
mirror Empty = Empty
mirror (Node left val right) = Node (mirror right) val (mirror left)

-- | Path from root to a value (if it exists)
pathTo :: forall a. Ord a => a -> Tree a -> Maybe (Array a)
pathTo _ Empty = Nothing
pathTo x (Node left val right)
  | x < val = map (Array.cons val) (pathTo x left)
  | x > val = map (Array.cons val) (pathTo x right)
  | otherwise = Just [val]

-- | Accumulator-based traversal for TCO demonstration
-- | This version uses an explicit stack to avoid deep recursion
inorderTCO :: forall a. Tree a -> Array a
inorderTCO tree = go [] [] tree
  where
  go :: Array a -> Array (Tuple (Tree a) Boolean) -> Tree a -> Array a
  go acc stack Empty = case Array.uncons stack of
    Nothing -> acc
    Just { head: Tuple t processed, tail } ->
      if processed
        then go acc tail t
        else case t of
          Empty -> go acc tail Empty
          Node left val right ->
            go (acc <> [val]) (Array.cons (Tuple right false) tail) left
  go acc stack (Node left val right) =
    go acc (Array.cons (Tuple (Node left val right) false) stack) Empty

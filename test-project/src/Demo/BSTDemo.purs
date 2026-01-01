-- | BST Demo - showcases the Binary Search Tree implementation
module Demo.BSTDemo where

import Prelude

import Data.Array as Array
import Data.BST as BST
import Data.Maybe (Maybe(..), fromMaybe)
import Effect (Effect)
import Effect.Console (log)

-- | Demo: Build a tree and perform operations
runDemo :: Effect Unit
runDemo = do
  log "=== Binary Search Tree Demo ==="
  log ""

  -- Build a tree from an array
  let values = [50, 30, 70, 20, 40, 60, 80, 10, 25, 35, 45]
  let tree = BST.fromArray values

  log "Building tree from: [50, 30, 70, 20, 40, 60, 80, 10, 25, 35, 45]"
  log ""

  -- Tree statistics
  log $ "Size: " <> show (BST.size tree)
  log $ "Height: " <> show (BST.height tree)
  log $ "Leaves: " <> show (BST.countLeaves tree)
  log $ "Balance factor: " <> show (BST.balanceFactor tree)
  log $ "Is balanced: " <> show (BST.isBalanced tree)
  log ""

  -- Traversals
  log "Traversals:"
  log $ "  In-order:    " <> show (BST.inorder tree)
  log $ "  Pre-order:   " <> show (BST.preorder tree)
  log $ "  Post-order:  " <> show (BST.postorder tree)
  -- log $ "  Level-order: " <> show (BST.levelOrder tree)  -- TODO: fix recursive let binding
  log ""

  -- Search operations
  log "Search operations:"
  log $ "  member 40: " <> show (BST.member 40 tree)
  log $ "  member 99: " <> show (BST.member 99 tree)
  log $ "  findMin: " <> show (BST.findMin tree)
  log $ "  findMax: " <> show (BST.findMax tree)
  log ""

  -- Path finding
  log "Paths from root:"
  log $ "  pathTo 45: " <> show (BST.pathTo 45 tree)
  log $ "  pathTo 10: " <> show (BST.pathTo 10 tree)
  log ""

  -- Deletion
  log "After deleting 30 (node with two children):"
  let tree2 = BST.delete 30 tree
  log $ "  In-order: " <> show (BST.inorder tree2)
  log $ "  Size: " <> show (BST.size tree2)
  log ""

  -- Map and fold
  log "Higher-order functions:"
  log $ "  Sum of all values: " <> show (BST.sumTree tree)
  log $ "  Doubled values: " <> show (BST.inorder (BST.mapTree (_ * 2) tree))
  log ""

  -- Depth exploration
  log "Values at each depth:"
  log $ "  Depth 0: " <> show (BST.atDepth 0 tree)
  log $ "  Depth 1: " <> show (BST.atDepth 1 tree)
  log $ "  Depth 2: " <> show (BST.atDepth 2 tree)
  log $ "  Depth 3: " <> show (BST.atDepth 3 tree)
  log ""

  -- Mirror
  log "Mirrored tree (in-order becomes descending):"
  log $ "  " <> show (BST.inorder (BST.mirror tree))
  log ""

  log "=== Demo Complete ==="

-- | Demo: Show TCO in action
-- | Note: BST insert is not tail-recursive (must rebuild path), so we use a smaller tree
-- | But member, lookup, findMin, findMax, and foldTree ARE tail-recursive!
runLargeTreeDemo :: Effect Unit
runLargeTreeDemo = do
  log "=== TCO Demonstration ==="
  log ""
  log "Functions with TCO optimization:"
  log "  - member: searches down tree without rebuilding"
  log "  - lookup: same as member"
  log "  - findMin/findMax: follows one path"
  log "  - foldTree: accumulator-based traversal"
  log ""

  -- Build a tree with 100 elements (fits in Python stack)
  let n = 100
  log $ "Building tree with " <> show n <> " elements..."
  let tree = BST.fromArray (Array.range 1 n)

  log $ "Size: " <> show (BST.size tree)
  log $ "Height: " <> show (BST.height tree)
  log ""

  -- These all use TCO!
  log "TCO'd operations on tree:"
  log $ "  findMin (TCO): " <> show (BST.findMin tree)
  log $ "  findMax (TCO): " <> show (BST.findMax tree)
  log $ "  member 50 (TCO): " <> show (BST.member 50 tree)
  log $ "  member 101 (TCO): " <> show (BST.member 101 tree)
  log $ "  lookup 75 (TCO): " <> show (BST.lookup 75 tree)
  log $ "  sumTree (foldTree with TCO): " <> show (BST.sumTree tree)
  log ""

  log "=== TCO Demo Complete ==="

-- | Main entry point
main :: Effect Unit
main = do
  runDemo
  log ""
  runLargeTreeDemo

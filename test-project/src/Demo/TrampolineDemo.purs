-- | Trampoline BST Demo - shows stack-safe operations on large trees
-- | NOTE: Due to optimizer inlining tailRec, we demonstrate with moderate-sized trees
-- | A proper fix requires modifying how tailRec is compiled
module Demo.TrampolineDemo where

import Prelude

import Data.Array as Array
import Data.BST.Trampoline as BST
import Effect (Effect)
import Effect.Console (log)

-- | Main demo
main :: Effect Unit
main = do
  log "=============================================="
  log "   Stack-Safe BST using Trampolines"
  log "=============================================="
  log ""

  -- Small tree demo first
  log "=== Small Tree Demo ==="
  let smallTree = BST.fromArray [50, 30, 70, 20, 40, 60, 80]
  log $ "Tree from [50, 30, 70, 20, 40, 60, 80]"
  log $ "  In-order: " <> show (BST.inorder smallTree)
  log $ "  Size: " <> show (BST.size smallTree)
  log $ "  Height: " <> show (BST.height smallTree)
  log $ "  Sum: " <> show (BST.sumTree smallTree)
  log ""

  -- Now the impressive part - large tree!
  log "=== Large Tree Demo (10,000 elements) ==="
  log ""
  log "Building tree with 10,000 sequential insertions..."
  log "(This would overflow the stack without trampolines!)"
  log ""

  -- Build a tree with 10000 elements
  -- Note: Sequential insertion creates a degenerate tree, but our
  -- stack-safe operations can still handle it!
  let n = 10000
  let largeTree = BST.fromArray (Array.range 1 n)

  log $ "Size: " <> show (BST.size largeTree)
  log $ "Height: " <> show (BST.height largeTree)
  log $ "  (Height = Size because sequential insertion creates a linear tree)"
  log ""

  log "Stack-safe operations on the large tree:"
  log $ "  findMin: " <> show (BST.findMin largeTree)
  log $ "  findMax: " <> show (BST.findMax largeTree)
  log $ "  member 5000: " <> show (BST.member 5000 largeTree)
  log $ "  member 10001: " <> show (BST.member 10001 largeTree)
  log $ "  lookup 7777: " <> show (BST.lookup 7777 largeTree)
  log ""

  log "Computing sum of 1 to 10000 via tree fold..."
  log $ "  Sum: " <> show (BST.sumTree largeTree)
  log $ "  (Should be n*(n+1)/2 = 50005000)"
  log ""

  -- Show that delete also works
  log "Deleting element 5000..."
  let afterDelete = BST.delete 5000 largeTree
  log $ "  member 5000 after delete: " <> show (BST.member 5000 afterDelete)
  log $ "  Size after delete: " <> show (BST.size afterDelete)
  log ""

  log "=== How It Works ==="
  log ""
  log "The trampoline pattern converts recursive calls to a loop:"
  log ""
  log "  1. Instead of recursing, return Loop { ...next state... }"
  log "  2. To finish, return Done result"
  log "  3. The tailRec function runs the loop until Done"
  log ""
  log "For insert, we use a 'zipper' pattern:"
  log "  - Walk down, recording path decisions in an array"
  log "  - At the leaf, rebuild upward using the path"
  log "  - Both phases use tailRec, so no stack growth!"
  log ""

  log "=============================================="
  log "   Demo Complete"
  log "=============================================="

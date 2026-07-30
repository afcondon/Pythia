-- | Connectivity over the in-service network.
-- |
-- | Graph search on our own data structure is not domain expertise borrowed
-- | from a library — it is the analysis itself, so it lives in PureScript.
-- | This replaces `_find_islands` (a BFS in `Grid_Cascade_foreign.py`) and the
-- | networkx calls in `Grid_Metrics_foreign.py`.
-- |
-- | Adjacency is a `Map Int (Set Int)`, and the searches carry `Set Int` for
-- | the visited frontier. This module was briefly written against sorted
-- | arrays and linear scans because purepy miscompiled the recursive local
-- | binding inside `Data.Map.Internal` and any import of it died before
-- | `main`; that is fixed (see `docs/RECURSIVE-LET-BINDING-ISSUE.md`) and the
-- | module now says what it means.
module Grid.Graph
  ( Adjacency
  , adjacencyFrom
  , reachableFrom
  , islandedBuses
  , components
  , degrees
  , diameter
  ) where

import Prelude

import Data.Array (filter, snoc, uncons)
import Data.Array as Array
import Data.Foldable (foldl, maximum)
import Data.Map (Map)
import Data.Map as Map
import Data.Maybe (Maybe(..), fromMaybe)
import Data.Set (Set)
import Data.Set as Set
import Data.Tuple (Tuple(..))

-- | Undirected adjacency: every bus present, so an isolated one is its own
-- | component rather than absent.
type Adjacency = Map Int (Set Int)

-- | Build adjacency from branch endpoints. Only in-service branches should be
-- | passed in — see `Grid.Types.branchEndpoints`.
adjacencyFrom :: Array Int -> Array { from :: Int, to :: Int } -> Adjacency
adjacencyFrom busIds edges = foldl addEdge empty edges
  where
  empty = Map.fromFoldable (map (\b -> Tuple b Set.empty) busIds)
  addEdge adj e = link e.from e.to (link e.to e.from adj)
  link a b = Map.alter (Just <<< Set.insert b <<< fromMaybe Set.empty) a

neighboursOf :: Adjacency -> Int -> Set Int
neighboursOf adj b = fromMaybe Set.empty (Map.lookup b adj)

-- | Breadth-first closure from a set of roots.
reachableFrom :: Adjacency -> Array Int -> Set Int
reachableFrom adj roots = go (Set.fromFoldable roots) roots
  where
  go seen frontier = case uncons frontier of
    Nothing -> seen
    Just { head: b, tail } ->
      let
        fresh = filter (\n -> not (Set.member n seen))
                       (Set.toUnfoldable (neighboursOf adj b))
      in
        go (foldl (flip Set.insert) seen fresh) (tail <> fresh)

-- | Buses with no path to any slack bus. These are what a cascade has cut
-- | adrift; their load is lost.
islandedBuses :: Adjacency -> Array Int -> Array Int -> Array Int
islandedBuses adj slackBuses allBuses =
  filter (\b -> not (Set.member b live)) allBuses
  where
  live = reachableFrom adj slackBuses

-- | Connected components, as arrays of bus ids.
components :: Adjacency -> Array Int -> Array (Array Int)
components adj allBuses = go allBuses Set.empty []
  where
  go remaining seen acc = case Array.head (filter (\b -> not (Set.member b seen)) remaining) of
    Nothing -> acc
    Just b ->
      let
        comp = reachableFrom adj [ b ]
      in
        go remaining (Set.union seen comp) (snoc acc (Set.toUnfoldable comp))

degrees :: Adjacency -> Array Int
degrees adj = map Set.size (Array.fromFoldable (Map.values adj))

-- | Shortest-path depths from one bus, by breadth-first layering.
depthsFrom :: Adjacency -> Int -> Map Int Int
depthsFrom adj root = go (Map.singleton root 0) [ root ]
  where
  go depths frontier = case uncons frontier of
    Nothing -> depths
    Just { head: b, tail } ->
      let
        d = fromMaybe 0 (Map.lookup b depths)
        fresh = filter (\n -> not (Map.member n depths))
                       (Set.toUnfoldable (neighboursOf adj b))
        depths' = foldl (\m n -> Map.insert n (d + 1) m) depths fresh
      in
        go depths' (tail <> fresh)

-- | Longest shortest-path, taken as the maximum over components so a split
-- | network still reports a meaningful figure rather than nothing.
diameter :: Adjacency -> Array Int -> Int
diameter adj allBuses =
  fromMaybe 0 (maximum (map componentDiameter (components adj allBuses)))
  where
  componentDiameter comp = fromMaybe 0 (maximum (map eccentricity comp))
  eccentricity root =
    fromMaybe 0 (maximum (Array.fromFoldable (Map.values (depthsFrom adj root))))

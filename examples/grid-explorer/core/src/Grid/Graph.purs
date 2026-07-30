-- | Connectivity over the in-service network.
-- |
-- | Graph search on our own data structure is not domain expertise borrowed
-- | from a library — it is the analysis itself, so it lives in PureScript.
-- | This replaces `_find_islands` (a BFS in `Grid_Cascade_foreign.py`) and the
-- | networkx calls in `Grid_Metrics_foreign.py`.
-- |
-- | NOTE: this wants `Data.Map` and `Data.Set` and cannot have them — purepy
-- | miscompiles the recursive local binding in `Data.Map.Internal`, so
-- | importing it kills the program at import time. See
-- | `docs/RECURSIVE-LET-BINDING-ISSUE.md`. Adjacency is therefore an array of
-- | records and membership is a linear scan. On a thirty-bus network that
-- | costs nothing; revert to `Data.Map` once the backend is fixed.
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

import Data.Array (concat, elem, filter, find, head, length, nub, snoc, uncons)
import Data.Foldable (maximum)
import Data.Maybe (Maybe(..), fromMaybe)

-- | Undirected adjacency: one entry per bus, neighbours de-duplicated.
type Adjacency = Array { bus :: Int, neighbours :: Array Int }

-- | Build adjacency from branch endpoints. Only in-service branches should be
-- | passed in — see `Grid.Types.branchEndpoints`. Every bus gets an entry, so
-- | an isolated one is its own component rather than absent.
adjacencyFrom :: Array Int -> Array { from :: Int, to :: Int } -> Adjacency
adjacencyFrom busIds edges = map entry busIds
  where
  entry b =
    { bus: b
    , neighbours: nub (concat (map (touching b) edges))
    }
  touching b e
    | e.from == b = [ e.to ]
    | e.to == b = [ e.from ]
    | otherwise = []

neighboursOf :: Adjacency -> Int -> Array Int
neighboursOf adj b = case find (\e -> e.bus == b) adj of
  Just e -> e.neighbours
  Nothing -> []

-- | Breadth-first closure from a set of roots.
reachableFrom :: Adjacency -> Array Int -> Array Int
reachableFrom adj roots = go (nub roots) (nub roots)
  where
  go seen frontier = case uncons frontier of
    Nothing -> seen
    Just { head: b, tail } ->
      let
        fresh = filter (\n -> not (elem n seen)) (neighboursOf adj b)
      in
        go (seen <> fresh) (tail <> fresh)

-- | Buses with no path to any slack bus. These are what a cascade has cut
-- | adrift; their load is lost.
islandedBuses :: Adjacency -> Array Int -> Array Int -> Array Int
islandedBuses adj slackBuses allBuses =
  filter (\b -> not (elem b live)) allBuses
  where
  live = reachableFrom adj slackBuses

-- | Connected components, as arrays of bus ids.
components :: Adjacency -> Array Int -> Array (Array Int)
components adj allBuses = go allBuses [] []
  where
  go remaining seen acc =
    case head (filter (\b -> not (elem b seen)) remaining) of
      Nothing -> acc
      Just b ->
        let
          comp = reachableFrom adj [ b ]
        in
          go remaining (seen <> comp) (snoc acc comp)

degrees :: Adjacency -> Array Int
degrees = map (length <<< _.neighbours)

-- | Shortest-path depths from one bus, by breadth-first layering. Association
-- | array rather than a Map, for the reason at the top of the module.
depthsFrom :: Adjacency -> Int -> Array { bus :: Int, depth :: Int }
depthsFrom adj root = go [ { bus: root, depth: 0 } ] [ root ]
  where
  go depths frontier = case uncons frontier of
    Nothing -> depths
    Just { head: b, tail } ->
      let
        d = fromMaybe 0 (map _.depth (find (\e -> e.bus == b) depths))
        known = map _.bus depths
        fresh = filter (\n -> not (elem n known)) (neighboursOf adj b)
        depths' = depths <> map (\n -> { bus: n, depth: d + 1 }) fresh
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
    fromMaybe 0 (maximum (map _.depth (depthsFrom adj root)))

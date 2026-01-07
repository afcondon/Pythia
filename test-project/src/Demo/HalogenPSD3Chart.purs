-- | Halogen + PSD3 WebSocket Chart - Real-time streaming visualization
-- | Connects to Python streaming server and visualizes data using PSD3
module Demo.HalogenPSD3Chart where

import Prelude

import Data.Array as Array
import Data.Int (toNumber)
import Data.Maybe (Maybe(..), fromMaybe)
import Data.Nullable (Nullable, toMaybe)
import Effect (Effect)
import Effect.Aff.Class (class MonadAff)
import Effect.Class (liftEffect)
import Effect.Console (log)
import Effect.Ref as Ref
import Halogen as H
import Halogen.Aff as HA
import Halogen.HTML as HH
import Halogen.HTML.Events as HE
import Halogen.HTML.Properties as HP
import Halogen.VDom.Driver (runUI)
import PSD3.AST (Tree)
import PSD3.AST as T
import PSD3.Expr.Friendly (num, text, attr, viewBox, x, y, x1, y1, x2, y2, fill, stroke, strokeWidth, textContent, transform, textAnchor)
import PSD3.Internal.Capabilities.Selection (select, renderTree, clear)
import PSD3.Interpreter.D3 (runD3v2M)
import PSD3.Internal.Selection.Types (ElementType(..))
import Web.WebSocket as WS

-- | Data point parsed from WebSocket message
type DataPoint =
  { tick :: Int
  , time :: Number
  , primary :: Number
  , secondary :: Number
  }

-- | FFI for parsing WebSocket JSON messages
foreign import parseDataMessageImpl :: String -> Nullable DataPoint

parseDataMessage :: String -> Maybe DataPoint
parseDataMessage = toMaybe <<< parseDataMessageImpl

-- | Component state
type State =
  { ws :: Maybe WS.WebSocket
  , dataBuffer :: Array DataPoint
  , status :: String
  , maxPoints :: Int
  }

-- | Component actions
data Action
  = Initialize
  | Connect
  | Disconnect
  | ReceiveData String

-- | Maximum points to display
maxBufferSize :: Int
maxBufferSize = 100

-- | Chart dimensions
chartWidth :: Number
chartWidth = 700.0

chartHeight :: Number
chartHeight = 350.0

margin :: { top :: Number, right :: Number, bottom :: Number, left :: Number }
margin = { top: 40.0, right: 30.0, bottom: 50.0, left: 60.0 }

-- | Main entry point
main :: Effect Unit
main = HA.runHalogenAff do
  body <- HA.awaitBody
  runUI component unit body

-- | Halogen component
component :: forall q i o m. MonadAff m => H.Component q i o m
component =
  H.mkComponent
    { initialState: \_ ->
        { ws: Nothing
        , dataBuffer: []
        , status: "Disconnected"
        , maxPoints: maxBufferSize
        }
    , render
    , eval: H.mkEval $ H.defaultEval
        { handleAction = handleAction
        , initialize = Just Initialize
        }
    }

-- | Render the component
render :: forall m. State -> H.ComponentHTML Action () m
render state =
  HH.div
    [ HP.style "font-family: system-ui; padding: 20px; background: #1a1a2e; color: #eee; min-height: 100vh;" ]
    [ HH.h1 [ HP.style "color: #7c3aed; margin-bottom: 5px;" ]
        [ HH.text "PSD3 Real-time Chart" ]
    , HH.p [ HP.style "color: #888; margin-top: 0;" ]
        [ HH.text "Halogen + PSD3 + Python WebSocket Streaming" ]

    -- Controls
    , HH.div [ HP.style "margin: 20px 0;" ]
        [ HH.button
            [ HE.onClick \_ -> Connect
            , HP.style buttonStyle
            , HP.disabled (state.status == "Connected")
            ]
            [ HH.text "Connect" ]
        , HH.button
            [ HE.onClick \_ -> Disconnect
            , HP.style disconnectStyle
            , HP.disabled (state.status /= "Connected")
            ]
            [ HH.text "Disconnect" ]
        , HH.span
            [ HP.style $ "margin-left: 20px; padding: 8px 15px; border-radius: 6px; " <> statusStyle state.status ]
            [ HH.text state.status ]
        ]

    -- Stats
    , HH.div [ HP.style "margin: 15px 0; color: #6ee7b7;" ]
        [ HH.text $ "Data points: " <> show (Array.length state.dataBuffer) <> " / " <> show state.maxPoints ]

    -- Chart container - PSD3 renders here
    , HH.div
        [ HP.id "psd3-chart"
        , HP.style "background: #0d1117; border-radius: 8px; padding: 10px; margin-top: 20px;"
        ]
        []
    ]
  where
    buttonStyle = "padding: 10px 20px; margin-right: 10px; background: #7c3aed; color: white; border: none; border-radius: 6px; cursor: pointer; font-weight: bold;"
    disconnectStyle = "padding: 10px 20px; background: #374151; color: white; border: none; border-radius: 6px; cursor: pointer;"
    statusStyle "Connected" = "background: #065f46; color: #6ee7b7;"
    statusStyle "Connecting" = "background: #78350f; color: #fcd34d;"
    statusStyle _ = "background: #7f1d1d; color: #fca5a5;"

-- | Handle actions
handleAction :: forall o m. MonadAff m => Action -> H.HalogenM State Action () o m Unit
handleAction = case _ of
  Initialize -> do
    liftEffect $ log "[PSD3] Component initialized"
    -- Render empty chart
    state <- H.get
    liftEffect $ renderChart state.dataBuffer

  Connect -> do
    H.modify_ _ { status = "Connecting" }

    -- Create refs for callbacks to update state
    dataRef <- liftEffect $ Ref.new ([] :: Array DataPoint)

    ws <- liftEffect $ WS.create "ws://localhost:8766"

    liftEffect $ WS.onOpen ws do
      log "[PSD3] WebSocket connected"

    liftEffect $ WS.onMessage ws \event -> do
      let msg = WS.getMessageData event
      case parseDataMessage msg of
        Just dp -> do
          -- Update the ref
          currentData <- Ref.read dataRef
          let newData = Array.takeEnd maxBufferSize (Array.snoc currentData dp)
          Ref.write newData dataRef
          -- Render the updated chart
          renderChart newData
        Nothing -> pure unit

    liftEffect $ WS.onClose ws \_ -> do
      log "[PSD3] WebSocket closed"

    liftEffect $ WS.onError ws do
      log "[PSD3] WebSocket error"

    H.modify_ _ { ws = Just ws, status = "Connected" }

  Disconnect -> do
    state <- H.get
    case state.ws of
      Just ws -> liftEffect $ WS.close ws
      Nothing -> pure unit
    H.modify_ _ { ws = Nothing, status = "Disconnected", dataBuffer = [] }

  ReceiveData _ -> pure unit

-- | Render the PSD3 chart with current data
renderChart :: Array DataPoint -> Effect Unit
renderChart dataPoints = runD3v2M do
  container <- select "#psd3-chart"

  let plotWidth = chartWidth - margin.left - margin.right
      plotHeight = chartHeight - margin.top - margin.bottom

      -- Get data ranges
      minTick = fromMaybe 0 $ map _.tick $ Array.head dataPoints
      maxTick = fromMaybe 100 $ map _.tick $ Array.last dataPoints
      tickRange = max 1 (maxTick - minTick)

      -- Scale helpers
      scaleX :: Int -> Number
      scaleX tick =
        let normalized = toNumber (tick - minTick) / toNumber tickRange
        in normalized * plotWidth

      scaleY :: Number -> Number
      scaleY value =
        -- Data ranges from about -1.5 to 1.5
        let normalized = (value + 1.5) / 3.0
        in plotHeight - (normalized * plotHeight)

      -- Build SVG path for line chart
      buildPath :: Array DataPoint -> String
      buildPath pts = case Array.uncons pts of
        Nothing -> ""
        Just { head: first, tail: rest } ->
          "M " <> show (scaleX first.tick) <> " " <> show (scaleY first.primary)
          <> Array.foldl (\acc pt -> acc <> " L " <> show (scaleX pt.tick) <> " " <> show (scaleY pt.primary)) "" rest

      buildPathSecondary :: Array DataPoint -> String
      buildPathSecondary pts = case Array.uncons pts of
        Nothing -> ""
        Just { head: first, tail: rest } ->
          "M " <> show (scaleX first.tick) <> " " <> show (scaleY first.secondary)
          <> Array.foldl (\acc pt -> acc <> " L " <> show (scaleX pt.tick) <> " " <> show (scaleY pt.secondary)) "" rest

      pathPrimary = buildPath dataPoints
      pathSecondary = buildPathSecondary dataPoints

      -- Y-axis gridlines
      gridValues = [-1.0, -0.5, 0.0, 0.5, 1.0]

  let tree :: Tree Unit
      tree =
        T.named SVG "svg"
          [ attr "width" $ num chartWidth
          , attr "height" $ num chartHeight
          , viewBox 0.0 0.0 chartWidth chartHeight
          ]
          `T.withChild`
            (T.named Group "chart"
              [ transform $ text $ "translate(" <> show margin.left <> "," <> show margin.top <> ")" ]
              `T.withChildren`
                [ -- Background
                  T.elem Rect
                    [ x $ num 0.0
                    , y $ num 0.0
                    , attr "width" $ num plotWidth
                    , attr "height" $ num plotHeight
                    , fill $ text "#161b22"
                    ]

                , -- Gridlines
                  T.named Group "grid" []
                    `T.withChildren`
                      (map (\v ->
                        T.elem Line
                          [ x1 $ num 0.0
                          , y1 $ num (scaleY v)
                          , x2 $ num plotWidth
                          , y2 $ num (scaleY v)
                          , stroke $ text "#30363d"
                          , strokeWidth $ num 1.0
                          ]
                      ) gridValues)

                , -- Zero line
                  T.elem Line
                    [ x1 $ num 0.0
                    , y1 $ num (scaleY 0.0)
                    , x2 $ num plotWidth
                    , y2 $ num (scaleY 0.0)
                    , stroke $ text "#484f58"
                    , strokeWidth $ num 2.0
                    ]

                , -- Secondary data line (cosine)
                  T.elem Path
                    [ attr "d" $ text pathSecondary
                    , fill $ text "none"
                    , stroke $ text "#22d3ee"
                    , strokeWidth $ num 2.0
                    , attr "opacity" $ num 0.7
                    ]

                , -- Primary data line (sine)
                  T.elem Path
                    [ attr "d" $ text pathPrimary
                    , fill $ text "none"
                    , stroke $ text "#a855f7"
                    , strokeWidth $ num 2.5
                    ]

                , -- Y-axis labels
                  T.named Group "y-labels" []
                    `T.withChildren`
                      (map (\v ->
                        T.elem Text
                          [ x $ num (-10.0)
                          , y $ num (scaleY v + 4.0)
                          , textAnchor $ text "end"
                          , fill $ text "#8b949e"
                          , attr "font-size" $ num 11.0
                          , textContent $ text $ show v
                          ]
                      ) gridValues)

                , -- Title
                  T.elem Text
                    [ x $ num (plotWidth / 2.0)
                    , y $ num (-15.0)
                    , textAnchor $ text "middle"
                    , fill $ text "#e6edf3"
                    , attr "font-size" $ num 14.0
                    , attr "font-weight" $ text "bold"
                    , textContent $ text "Real-time Streaming Data"
                    ]

                , -- Legend
                  T.named Group "legend"
                    [ transform $ text $ "translate(" <> show (plotWidth - 120.0) <> ", 15)" ]
                    `T.withChildren`
                      [ T.elem Line
                          [ x1 $ num 0.0, y1 $ num 0.0, x2 $ num 20.0, y2 $ num 0.0
                          , stroke $ text "#a855f7", strokeWidth $ num 2.5 ]
                      , T.elem Text
                          [ x $ num 25.0, y $ num 4.0, fill $ text "#8b949e"
                          , attr "font-size" $ num 11.0, textContent $ text "Primary" ]
                      , T.elem Line
                          [ x1 $ num 0.0, y1 $ num 18.0, x2 $ num 20.0, y2 $ num 18.0
                          , stroke $ text "#22d3ee", strokeWidth $ num 2.0 ]
                      , T.elem Text
                          [ x $ num 25.0, y $ num 22.0, fill $ text "#8b949e"
                          , attr "font-size" $ num 11.0, textContent $ text "Secondary" ]
                      ]
                ])

  clear "#psd3-chart"
  _ <- renderTree container tree
  pure unit

-- | Halogen WebSocket demo - connects to Python streaming server
module Demo.HalogenWebSocket where

import Prelude

import Data.Array as Array
import Data.Maybe (Maybe(..))
import Data.String (joinWith)
import Effect (Effect)
import Effect.Aff.Class (class MonadAff)
import Effect.Class (liftEffect)
import Effect.Console (log)
import Halogen as H
import Halogen.Aff as HA
import Halogen.HTML as HH
import Halogen.HTML.Events as HE
import Halogen.HTML.Properties as HP
import Halogen.VDom.Driver (runUI)
import Web.WebSocket as WS

-- | Component state
type State =
  { ws :: Maybe WS.WebSocket
  , messageCount :: Int
  , lastMessage :: String
  , status :: String
  }

-- | Component actions
data Action
  = Connect
  | Disconnect

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
        , messageCount: 0
        , lastMessage: ""
        , status: "Disconnected"
        }
    , render
    , eval: H.mkEval $ H.defaultEval { handleAction = handleAction }
    }

render :: forall m. State -> H.ComponentHTML Action () m
render state =
  HH.div
    [ HP.style "font-family: system-ui; padding: 20px; background: #1a1a2e; color: #eee; min-height: 100vh;" ]
    [ HH.h1 [ HP.style "color: #7c3aed;" ] [ HH.text "Halogen WebSocket Demo" ]
    , HH.p [ HP.style "color: #888;" ] [ HH.text "PureScript Halogen + Python WebSocket Server" ]
    , HH.div [ HP.style "margin: 20px 0;" ]
        [ HH.button
            [ HE.onClick \_ -> Connect
            , HP.style "padding: 10px 20px; margin-right: 10px; background: #7c3aed; color: white; border: none; border-radius: 6px; cursor: pointer;"
            , HP.disabled (state.status == "Connected")
            ]
            [ HH.text "Connect" ]
        , HH.button
            [ HE.onClick \_ -> Disconnect
            , HP.style "padding: 10px 20px; background: #374151; color: white; border: none; border-radius: 6px; cursor: pointer;"
            , HP.disabled (state.status /= "Connected")
            ]
            [ HH.text "Disconnect" ]
        , HH.span
            [ HP.style $ "margin-left: 20px; padding: 8px 15px; border-radius: 6px; " <> statusStyle state.status ]
            [ HH.text state.status ]
        ]
    , HH.p [ HP.style "margin: 10px 0; color: #888;" ]
        [ HH.text $ "Check browser console for messages (open DevTools)" ]
    , HH.p [ HP.style "color: #6ee7b7;" ]
        [ HH.text $ "Message count: " <> show state.messageCount ]
    ]
  where
    statusStyle "Connected" = "background: #065f46; color: #6ee7b7;"
    statusStyle "Connecting" = "background: #78350f; color: #fcd34d;"
    statusStyle _ = "background: #7f1d1d; color: #fca5a5;"

-- | Handle actions
handleAction :: forall o m. MonadAff m => Action -> H.HalogenM State Action () o m Unit
handleAction = case _ of
  Connect -> do
    H.modify_ _ { status = "Connecting" }
    ws <- liftEffect $ WS.create "ws://localhost:8766"

    -- Set up event handlers (they log to console)
    liftEffect $ WS.onOpen ws do
      log "[Halogen] WebSocket OPEN"

    liftEffect $ WS.onMessage ws \event -> do
      let msg = WS.getMessageData event
      log $ "[Halogen] MSG: " <> msg

    liftEffect $ WS.onClose ws \event -> do
      log $ "[Halogen] CLOSE: " <> show event.code

    liftEffect $ WS.onError ws do
      log "[Halogen] ERROR"

    H.modify_ _ { ws = Just ws, status = "Connected" }
    liftEffect $ log "[Halogen] Connected to ws://localhost:8766"

  Disconnect -> do
    state <- H.get
    case state.ws of
      Just ws -> liftEffect $ WS.close ws
      Nothing -> pure unit
    H.modify_ _ { ws = Nothing, status = "Disconnected" }
    liftEffect $ log "[Halogen] Disconnected"

-- | WebSocket client bindings for browser WebSocket API.
-- |
-- | This module provides Effect-based bindings to the browser's native
-- | WebSocket API for PureScript frontends (JavaScript target).
-- |
-- | Example:
-- | ```purescript
-- | main :: Effect Unit
-- | main = do
-- |   ws <- WebSocket.create "ws://localhost:8765"
-- |   WebSocket.onOpen ws do
-- |     log "Connected!"
-- |     WebSocket.send ws "Hello, server!"
-- |   WebSocket.onMessage ws \event -> do
-- |     let msg = WebSocket.getMessageData event
-- |     log $ "Received: " <> msg
-- |   WebSocket.onClose ws \event ->
-- |     log $ "Disconnected: " <> show event.code
-- | ```
module Web.WebSocket
  ( WebSocket
  , ReadyState(..)
  , CloseEvent
  , MessageEvent
  -- Construction
  , create
  , createWithProtocol
  -- State
  , readyState
  , isConnected
  , getUrl
  , getProtocol
  -- Sending
  , send
  , sendText
  -- Event handlers
  , onOpen
  , onClose
  , onMessage
  , onError
  -- Lifecycle
  , close
  , closeWithCode
  -- Event data
  , getMessageData
  ) where

import Prelude

import Data.Function.Uncurried (Fn2, Fn3, runFn2, runFn3)
import Effect (Effect)

-- | Opaque WebSocket handle.
foreign import data WebSocket :: Type

-- | Message event from the server.
foreign import data MessageEvent :: Type

-- | WebSocket ready states.
data ReadyState
  = Connecting  -- 0
  | Open        -- 1
  | Closing     -- 2
  | Closed      -- 3

derive instance eqReadyState :: Eq ReadyState

instance showReadyState :: Show ReadyState where
  show Connecting = "Connecting"
  show Open = "Open"
  show Closing = "Closing"
  show Closed = "Closed"

-- | Close event data.
type CloseEvent =
  { code :: Int
  , reason :: String
  , wasClean :: Boolean
  }

--------------------------------------------------------------------------------
-- Construction
--------------------------------------------------------------------------------

-- | Create a WebSocket connection to the given URL.
foreign import create :: String -> Effect WebSocket

-- | Create a WebSocket with a subprotocol.
foreign import createWithProtocolImpl :: Fn2 String String (Effect WebSocket)

createWithProtocol :: String -> String -> Effect WebSocket
createWithProtocol url protocol = runFn2 createWithProtocolImpl url protocol

--------------------------------------------------------------------------------
-- State
--------------------------------------------------------------------------------

-- | Get the current ready state.
foreign import readyStateImpl :: WebSocket -> Effect Int

readyState :: WebSocket -> Effect ReadyState
readyState ws = do
  state <- readyStateImpl ws
  pure case state of
    0 -> Connecting
    1 -> Open
    2 -> Closing
    _ -> Closed

-- | Check if the WebSocket is in the Open state.
isConnected :: WebSocket -> Effect Boolean
isConnected ws = do
  state <- readyState ws
  pure (state == Open)

-- | Get the WebSocket URL.
foreign import getUrl :: WebSocket -> Effect String

-- | Get the negotiated protocol (empty string if none).
foreign import getProtocol :: WebSocket -> Effect String

--------------------------------------------------------------------------------
-- Sending
--------------------------------------------------------------------------------

-- | Send a text message.
foreign import sendText :: WebSocket -> String -> Effect Unit

-- | Alias for sendText.
send :: WebSocket -> String -> Effect Unit
send = sendText

--------------------------------------------------------------------------------
-- Event Handlers
--------------------------------------------------------------------------------

-- | Set handler for when the connection opens.
foreign import onOpen :: WebSocket -> Effect Unit -> Effect Unit

-- | Set handler for when the connection closes.
foreign import onCloseImpl :: Fn2 WebSocket (CloseEvent -> Effect Unit) (Effect Unit)

onClose :: WebSocket -> (CloseEvent -> Effect Unit) -> Effect Unit
onClose ws handler = runFn2 onCloseImpl ws handler

-- | Set handler for when a message is received.
foreign import onMessageImpl :: Fn2 WebSocket (MessageEvent -> Effect Unit) (Effect Unit)

onMessage :: WebSocket -> (MessageEvent -> Effect Unit) -> Effect Unit
onMessage ws handler = runFn2 onMessageImpl ws handler

-- | Set handler for errors.
foreign import onErrorImpl :: Fn2 WebSocket (Effect Unit) (Effect Unit)

onError :: WebSocket -> Effect Unit -> Effect Unit
onError ws handler = runFn2 onErrorImpl ws handler

--------------------------------------------------------------------------------
-- Lifecycle
--------------------------------------------------------------------------------

-- | Close the connection with normal closure (1000).
foreign import close :: WebSocket -> Effect Unit

-- | Close with a specific code and reason.
foreign import closeWithCodeImpl :: Fn3 WebSocket Int String (Effect Unit)

closeWithCode :: WebSocket -> Int -> String -> Effect Unit
closeWithCode ws code reason = runFn3 closeWithCodeImpl ws code reason

--------------------------------------------------------------------------------
-- Event Data
--------------------------------------------------------------------------------

-- | Get the message data from a MessageEvent as a string.
foreign import getMessageData :: MessageEvent -> String

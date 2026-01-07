-- | WebSocket server bindings for Python's websockets library.
-- |
-- | This module provides async WebSocket server functionality that integrates
-- | with Control.Monad.Asyncio. It uses the Python `websockets` library.
-- |
-- | Example:
-- | ```purescript
-- | main :: Effect Unit
-- | main = Asyncio.run_ do
-- |   server <- WebSocket.serve 8765 \conn -> do
-- |     result <- WebSocket.receive conn
-- |     case result of
-- |       Right msg -> WebSocket.sendText conn $ "Echo: " <> msg
-- |       Left _ -> pure unit
-- |   Asyncio.sleep 999999999.0  -- Keep server running
-- | ```
module Server.WebSocket
  ( WebSocketServer
  , WebSocketConnection
  , CloseCode(..)
  -- Server lifecycle
  , serve
  , stop
  -- Sending messages
  , sendText
  , send
  -- Receiving messages
  , receive
  -- Connection management
  , close
  , closeWithCode
  , isOpen
  , getRemoteAddress
  , getPath
  -- Broadcast
  , broadcast
  , broadcastExcept
  , getConnections
  ) where

import Prelude

import Control.Monad.Asyncio (Asyncio)
import Data.Either (Either)
import Data.Function.Uncurried (Fn2, Fn3, runFn2, runFn3)
import Effect (Effect)

-- | Opaque type for WebSocket server instance.
foreign import data WebSocketServer :: Type

-- | Opaque type for individual WebSocket connection.
foreign import data WebSocketConnection :: Type

-- | WebSocket close codes (RFC 6455).
data CloseCode
  = NormalClosure        -- 1000
  | GoingAway            -- 1001
  | ProtocolError        -- 1002
  | UnsupportedData      -- 1003
  | InvalidData          -- 1007
  | PolicyViolation      -- 1008
  | MessageTooBig        -- 1009
  | InternalError        -- 1011
  | CustomCode Int       -- 3000-4999

-- | Convert close code to integer for FFI.
closeCodeToInt :: CloseCode -> Int
closeCodeToInt NormalClosure = 1000
closeCodeToInt GoingAway = 1001
closeCodeToInt ProtocolError = 1002
closeCodeToInt UnsupportedData = 1003
closeCodeToInt InvalidData = 1007
closeCodeToInt PolicyViolation = 1008
closeCodeToInt MessageTooBig = 1009
closeCodeToInt InternalError = 1011
closeCodeToInt (CustomCode n) = n

--------------------------------------------------------------------------------
-- Server Lifecycle
--------------------------------------------------------------------------------

-- | Start a WebSocket server on the given port.
-- | The handler is called for each new connection.
foreign import serveImpl
  :: Fn2 Int (WebSocketConnection -> Asyncio Unit) (Asyncio WebSocketServer)

serve :: Int -> (WebSocketConnection -> Asyncio Unit) -> Asyncio WebSocketServer
serve port handler = runFn2 serveImpl port handler

-- | Stop the WebSocket server gracefully.
foreign import stop :: WebSocketServer -> Asyncio Unit

--------------------------------------------------------------------------------
-- Sending Messages
--------------------------------------------------------------------------------

-- | Send a text message to a connection.
foreign import sendText :: WebSocketConnection -> String -> Asyncio Unit

-- | Alias for sendText.
send :: WebSocketConnection -> String -> Asyncio Unit
send = sendText

--------------------------------------------------------------------------------
-- Receiving Messages
--------------------------------------------------------------------------------

-- | Receive a message from a connection.
-- | Blocks until a message arrives or the connection closes.
-- | Returns Left with error message on failure/disconnect.
foreign import receive :: WebSocketConnection -> Asyncio (Either String String)

--------------------------------------------------------------------------------
-- Connection Management
--------------------------------------------------------------------------------

-- | Close a connection with normal closure code (1000).
foreign import close :: WebSocketConnection -> Asyncio Unit

-- | Close a connection with a specific code and reason.
foreign import closeWithCodeImpl
  :: Fn3 WebSocketConnection Int String (Asyncio Unit)

closeWithCode :: WebSocketConnection -> CloseCode -> String -> Asyncio Unit
closeWithCode conn code reason =
  runFn3 closeWithCodeImpl conn (closeCodeToInt code) reason

-- | Check if a connection is still open (synchronous Effect).
foreign import isOpen :: WebSocketConnection -> Effect Boolean

-- | Get the remote address as "host:port" string.
foreign import getRemoteAddress :: WebSocketConnection -> Effect String

-- | Get the request path (e.g., "/chat").
foreign import getPath :: WebSocketConnection -> Effect String

--------------------------------------------------------------------------------
-- Broadcast
--------------------------------------------------------------------------------

-- | Broadcast a message to all connected clients.
foreign import broadcastImpl
  :: Fn2 WebSocketServer String (Asyncio Unit)

broadcast :: WebSocketServer -> String -> Asyncio Unit
broadcast server msg = runFn2 broadcastImpl server msg

-- | Broadcast to all clients except one (useful for echo servers).
foreign import broadcastExceptImpl
  :: Fn3 WebSocketServer WebSocketConnection String (Asyncio Unit)

broadcastExcept
  :: WebSocketServer
  -> WebSocketConnection
  -> String
  -> Asyncio Unit
broadcastExcept server except msg =
  runFn3 broadcastExceptImpl server except msg

-- | Get all currently connected clients.
foreign import getConnections :: WebSocketServer -> Effect (Array WebSocketConnection)

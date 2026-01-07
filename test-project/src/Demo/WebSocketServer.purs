-- | WebSocket echo/chat server demo.
-- |
-- | Run with:
-- | ```
-- | spago build && purepy output output-py-new
-- | cp src/Server/WebSocket.py output-py-new/server_websocket_foreign.py
-- | cd output-py-new && python3 -c "import demo_websocket_server; demo_websocket_server.main()"
-- | ```
module Demo.WebSocketServer where

import Prelude

import Control.Monad.Asyncio (Asyncio)
import Control.Monad.Asyncio as Asyncio
import Data.Either (Either(..))
import Effect (Effect)
import Effect.Console (log)
import Server.WebSocket as WS

-- | Handle a single client connection.
handleConnection :: WS.WebSocketServer -> WS.WebSocketConnection -> Asyncio Unit
handleConnection server conn = do
  -- Get client info
  addr <- Asyncio.liftEffect $ WS.getRemoteAddress conn
  _ <- Asyncio.liftEffect $ log $ "[Server] Client connected: " <> addr

  -- Send welcome message
  WS.sendText conn $ "Welcome! You are connected from " <> addr

  -- Broadcast join notification
  WS.broadcastExcept server conn $ "[Server] " <> addr <> " joined the chat"

  -- Start receive loop
  receiveLoop server conn addr

-- | Continuously receive and broadcast messages.
receiveLoop
  :: WS.WebSocketServer
  -> WS.WebSocketConnection
  -> String
  -> Asyncio Unit
receiveLoop server conn addr = do
  result <- WS.receive conn
  case result of
    Left err -> do
      -- Connection closed
      _ <- Asyncio.liftEffect $ log $ "[Server] " <> addr <> " disconnected: " <> err
      WS.broadcast server $ "[Server] " <> addr <> " left the chat"
    Right msg -> do
      -- Log and broadcast message
      _ <- Asyncio.liftEffect $ log $ "[" <> addr <> "] " <> msg
      WS.broadcast server $ "[" <> addr <> "] " <> msg
      -- Continue receiving
      receiveLoop server conn addr

-- | Simple echo handler (no broadcast, for testing).
echoHandler :: WS.WebSocketConnection -> Asyncio Unit
echoHandler conn = do
  addr <- Asyncio.liftEffect $ WS.getRemoteAddress conn
  _ <- Asyncio.liftEffect $ log $ "[Server] Client connected: " <> addr
  WS.sendText conn $ "Welcome! You are connected from " <> addr
  echoLoop conn addr
  where
    echoLoop c a = do
      result <- WS.receive c
      case result of
        Left err -> Asyncio.liftEffect $ log $ "[Server] " <> a <> " disconnected: " <> err
        Right msg -> do
          _ <- Asyncio.liftEffect $ log $ "[" <> a <> "] " <> msg
          WS.sendText c $ "Echo: " <> msg
          echoLoop c a

-- | Main entry point.
main :: Effect Unit
main = Asyncio.run_ do
  _ <- Asyncio.liftEffect $ log "Starting WebSocket server on ws://0.0.0.0:8765"
  _ <- Asyncio.liftEffect $ log "Open demo/websocket-client.html in a browser to connect"

  -- Start server with echo handler
  _server <- WS.serve 8765 echoHandler

  _ <- Asyncio.liftEffect $ log "WebSocket server running. Press Ctrl+C to stop."

  -- Keep server running indefinitely
  Asyncio.sleep 999999999.0

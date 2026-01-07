-- | Live data streaming server demo.
-- |
-- | Streams real-time data points to connected WebSocket clients.
-- | Demonstrates bidirectional communication with Python backend.
-- |
-- | Run with:
-- | ```
-- | cd output-py-new
-- | python3 -c "import demo_streaming_server; demo_streaming_server.main()"
-- | ```
-- | Then open demo/streaming-chart.html in a browser.
module Demo.StreamingServer where

import Prelude

import Control.Monad.Asyncio (Asyncio)
import Control.Monad.Asyncio as Asyncio
import Data.Either (Either(..))
import Effect (Effect)
import Effect.Console (log)
import Server.WebSocket as WS

-- | Generate streaming data via FFI (Python handles the math)
foreign import generateDataPoint :: Int -> Effect String

-- | Handle a streaming client connection.
-- | Sends data points at regular intervals until client disconnects.
handleStreamingClient :: WS.WebSocketConnection -> Asyncio Unit
handleStreamingClient conn = do
  addr <- Asyncio.liftEffect $ WS.getRemoteAddress conn
  _ <- Asyncio.liftEffect $ log $ "[Stream] Client connected: " <> addr

  -- Send initial message
  WS.sendText conn """{"type":"connected","message":"Streaming server ready"}"""

  -- Start streaming loop
  streamLoop conn addr 0

-- | Stream data points with a small delay between each.
streamLoop :: WS.WebSocketConnection -> String -> Int -> Asyncio Unit
streamLoop conn addr tick = do
  -- Check if still connected
  isConnected <- Asyncio.liftEffect $ WS.isOpen conn
  if not isConnected
    then Asyncio.liftEffect $ log $ "[Stream] " <> addr <> " disconnected"
    else do
      -- Generate and send data point
      dataPoint <- Asyncio.liftEffect $ generateDataPoint tick
      WS.sendText conn dataPoint

      -- Small delay (50ms = 20 points per second)
      Asyncio.sleep 50.0

      -- Continue streaming
      streamLoop conn addr (tick + 1)

-- | Main entry point.
main :: Effect Unit
main = Asyncio.run_ do
  _ <- Asyncio.liftEffect $ log "Starting streaming data server on ws://0.0.0.0:8766"
  _ <- Asyncio.liftEffect $ log "Open demo/streaming-chart.html in a browser to connect"

  -- Start WebSocket server
  _server <- WS.serve 8766 handleStreamingClient

  _ <- Asyncio.liftEffect $ log "Streaming server running. Press Ctrl+C to stop."

  -- Keep server running
  Asyncio.sleep 999999999.0

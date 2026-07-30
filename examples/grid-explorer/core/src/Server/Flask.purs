-- | Flask web server FFI bindings
module Server.Flask
  ( Flask
  , Request
  , Response
  , createApp
  , route
  , get
  , getWith
  , post
  , jsonify
  , run
  , runWithOptions
  , getRequestJson
  , requestNumber
  , requestArrayInt
  , cors
  ) where

import Prelude
import Effect (Effect)
import Data.Function.Uncurried (Fn2, Fn3, runFn2, runFn3)

-- | Flask application handle
foreign import data Flask :: Type

-- | Request object
foreign import data Request :: Type

-- | Response object
foreign import data Response :: Type

-- | Create a new Flask application
foreign import createApp :: String -> Effect Flask

-- | Register a route with a handler
foreign import routeImpl :: Fn3 Flask String (Effect Response) (Effect Unit)

route :: Flask -> String -> Effect Response -> Effect Unit
route app path handler = runFn3 routeImpl app path handler

-- | Register a GET route
foreign import getImpl :: Fn3 Flask String (Effect Response) (Effect Unit)

get :: Flask -> String -> Effect Response -> Effect Unit
get app path handler = runFn3 getImpl app path handler

-- | Register a GET route whose handler sees the request, for query parameters.
foreign import getWithImpl :: Fn3 Flask String (Request -> Effect Response) (Effect Unit)

getWith :: Flask -> String -> (Request -> Effect Response) -> Effect Unit
getWith app path handler = runFn3 getWithImpl app path handler

-- | Register a POST route
foreign import postImpl :: Fn3 Flask String (Request -> Effect Response) (Effect Unit)

post :: Flask -> String -> (Request -> Effect Response) -> Effect Unit
post app path handler = runFn3 postImpl app path handler

-- | Convert a value to JSON response
foreign import jsonify :: forall a. a -> Response

-- | Get JSON body from request
foreign import getRequestJson :: Request -> Effect (forall a. a)

-- | Read a numeric query parameter, falling back to a default when it is
-- | absent or unparseable. Pure: the request is immutable for the lifetime of
-- | the handler, so reading a parameter twice cannot disagree.
foreign import requestNumberImpl :: Fn3 Request String Number Number

requestNumber :: Request -> String -> Number -> Number
requestNumber req key fallback = runFn3 requestNumberImpl req key fallback

-- | Read an array of ints from the JSON body, empty when absent.
foreign import requestArrayIntImpl :: Fn2 Request String (Array Int)

requestArrayInt :: Request -> String -> Array Int
requestArrayInt req key = runFn2 requestArrayIntImpl req key

-- | Run the Flask app (blocking)
foreign import runImpl :: Fn2 Flask Int (Effect Unit)

run :: Flask -> Int -> Effect Unit
run app port = runFn2 runImpl app port

-- | Run with more options
foreign import runWithOptionsImpl :: Fn3 Flask String Int (Effect Unit)

runWithOptions :: Flask -> String -> Int -> Effect Unit
runWithOptions app host port = runFn3 runWithOptionsImpl app host port

-- | Enable CORS (for browser access)
foreign import cors :: Flask -> Effect Unit

-- | Flask web server FFI bindings
module Server.Flask
  ( Flask
  , Request
  , Response
  , createApp
  , route
  , get
  , post
  , jsonify
  , run
  , runWithOptions
  , getRequestJson
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

-- | Register a POST route
foreign import postImpl :: Fn3 Flask String (Request -> Effect Response) (Effect Unit)

post :: Flask -> String -> (Request -> Effect Response) -> Effect Unit
post app path handler = runFn3 postImpl app path handler

-- | Convert a value to JSON response
foreign import jsonify :: forall a. a -> Response

-- | Get JSON body from request
foreign import getRequestJson :: Request -> Effect (forall a. a)

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

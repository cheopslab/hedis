{-# LANGUAGE OverloadedStrings          #-}
{-# LANGUAGE DataKinds                  #-}
{-# LANGUAGE DeriveDataTypeable         #-}
{-# LANGUAGE DeriveGeneric              #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE OverloadedStrings          #-}
{-# LANGUAGE TypeOperators              #-}
{-# LANGUAGE LambdaCase                 #-}
module Main where

import           Control.Lens
import qualified Cheops.K8s as K8s
import           Data.Aeson
import           Data.Proxy
import           Data.Swagger
import           Servant
import           Servant.Swagger
import           Servant.Swagger.UI
import           Servant.API.Generic
import           Network.Wai.Handler.Warp as Wrap

newtype Item = Item { itemText :: String }
  deriving (Eq, Show, Generic)

instance ToJSON Item
instance FromJSON Item
instance ToSchema Item

type ExampleAPI = "example" :> Get '[JSON] String

swaggerItem :: Swagger
swaggerItem =
  toSwagger (Proxy :: Proxy ExampleAPI)
    & info.title        .~ "Example API"
    & info.version      .~ "1.0"
    & info.description  ?~ "This is a example description"
    & host              ?~ "localhost"

type API = SwaggerSchemaUI "swagger-ui" "swagger.json"
      :<|> ExampleAPI


k8sConfig :: K8s.Config
k8sConfig = K8s.Config
  { K8s.configPort = 10022
  , K8s.configReady = ["ready"]
  , K8s.configHealth = ["health"]
  , K8s.configPreStopHook =["stop"]
  }

exampleApp :: Application
exampleApp = serve (Proxy :: Proxy API) server

server :: Server API
server = swaggerSchemaUIServer swaggerItem
    :<|> serveExample
 where serveExample = pure "Hello, Haskell!"

main :: IO ()
main = do
  let p = 8000
  putStrLn $ "Run server on port " ++ show p
  K8s.run k8sConfig (pure ())
    $ Wrap.run p exampleApp

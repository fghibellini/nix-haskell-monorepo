{-# LANGUAGE DataKinds #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE TypeOperators #-}
{-# LANGUAGE OverloadedStrings #-}

module Main where

import           Data.Aeson
import           GHC.Generics
import           Network.Wai
import           Network.Wai.Handler.Warp
import           Servant
import           System.IO
import           Data.UUID
import           Data.Text
import           Data.IORef (IORef, newIORef, readIORef, modifyIORef')
import           Control.Monad.IO.Class (liftIO)

data Order = Order { cartId :: UUID } deriving (Generic)
instance FromJSON Order

data PostOrderResponse = PostOrderResponse { status :: Text } deriving (Generic)
instance ToJSON PostOrderResponse

type OrderApi =
  "orderCount" :> Get '[JSON] Int :<|>
  "postOrder" :> ReqBody '[JSON] Order :> Post '[JSON] PostOrderResponse

orderApi :: Proxy OrderApi
orderApi = Proxy

main :: IO ()
main = do
  let port = 3000
      settings =
        setPort port $
        setBeforeMainLoop (hPutStrLn stderr ("listening on port " ++ show port)) $
        defaultSettings
  s <- server
  runSettings settings (serve orderApi s)

server :: IO (Server OrderApi)
server = do
  ref <- newIORef []
  pure (orderCount ref :<|> postOrder ref)

orderCount :: IORef [a] -> Handler Int
orderCount ref = liftIO $ Prelude.length <$> readIORef ref

postOrder :: IORef [Order] -> Order -> Handler PostOrderResponse
postOrder ref order = do
  liftIO $ modifyIORef' ref (\os -> order : os)
  pure $ PostOrderResponse { status = "OK" }



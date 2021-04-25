{-# LANGUAGE OverloadedStrings #-}
module Honeycomb.Tracing.Instrumentation.Postgresql where
import Database.PostgreSQL.Simple hiding
  ( connectPostgreSQL 
  , close
  , connect
  , query
  , query_
  , queryWith
  , queryWith_
  , fold
  , foldWithOptions
  , fold_
  , foldWithOptions_
  , forEach
  , forEach_
  , returning
  , foldWith
  , foldWithOptionsAndParser
  , foldWith_
  )
import Control.Monad.IO.Class
import qualified Database.PostgreSQL.Simple as Simple
import Honeycomb.Tracing.Monad
import Data.ByteString.Char8
import Database.PostgreSQL.Simple.FromRow
import Data.Int
import UnliftIO
import Honeycomb.Tracing.Fields
import Data.Text (Text)

connectPostgreSQL :: (MonadTrace env m) => ByteString -> m Simple.Connection
connectPostgreSQL = spanningIO "connectPostgresql" . liftIO . Simple.connectPostgreSQL 

close :: (MonadTrace env m) => Simple.Connection -> m ()
close ci = spanningIO "close" $ do
  annotateBasics
  liftIO $ Simple.close ci

connect :: (MonadTrace env m) => Simple.ConnectInfo -> m Simple.Connection
connect ci = spanningIO "connect" $ do
  annotateBasics
  liftIO $ Simple.connect ci

query :: (MonadTrace env m, Simple.ToRow q, Simple.FromRow r) => Simple.Connection -> Simple.Query -> q -> m [r]
query c q params = spanningIO "query" $ do
  annotateBasics
  annotateQuery q
  liftIO $ Simple.query c q params

query_ :: (MonadTrace env m, FromRow r) => Connection -> Query -> m [r]
query_ c q = spanningIO "query_" $ do
  annotateBasics
  annotateQuery q
  liftIO $ Simple.query_ c q

queryWith :: (MonadTrace env m, ToRow q) => RowParser r -> Connection -> Query -> q -> m [r]
queryWith p c q params = spanningIO "queryWith" $ do
  annotateBasics
  annotateQuery q
  liftIO $ Simple.queryWith p c q params

queryWith_ :: (MonadTrace env m) => RowParser r -> Connection -> Query -> m [r]
queryWith_ r c q = spanningIO "queryWith_" $ do
  annotateBasics
  annotateQuery q
  liftIO $ Simple.queryWith_ r c q

fold :: (MonadUnliftIO m, MonadTrace env m, FromRow row, ToRow params) => Connection -> Query -> params -> a -> (a -> row -> m a) -> m a
fold c q ps x f = spanning "fold" $ do
  annotateBasics
  annotateQuery q
  withRunInIO $ \runInIO -> do 
    Simple.fold c q ps x (\x' r -> runInIO $ f x' r)

foldWithOptions :: (MonadUnliftIO m, MonadTrace env m, FromRow row, ToRow params) => FoldOptions -> Connection -> Query -> params -> a -> (a -> row -> m a) -> m a
foldWithOptions fopts c q ps x f = spanning "foldWithOptions" $ do
  annotateBasics
  annotateQuery q
  withRunInIO $ \runInIO -> do
    Simple.foldWithOptions fopts c q ps x (\x' r -> runInIO $ f x' r)

fold_ :: (MonadUnliftIO m, MonadTrace env m, FromRow r) => Connection -> Query -> a -> (a -> r -> m a) -> m a
fold_ c q x f = spanning "fold_" $ do
  annotateBasics
  annotateQuery q
  withRunInIO $ \runInIO -> do
    Simple.fold_ c q x (\x' r -> runInIO $ f x' r)

foldWithOptions_ :: (MonadUnliftIO m, MonadTrace env m, FromRow r) => FoldOptions -> Connection -> Query -> a -> (a -> r -> m a) -> m a
foldWithOptions_ fopts c q x f = spanning "foldWithOptions_" $ do
  annotateBasics
  annotateQuery q
  withRunInIO $ \runInIO -> do
    Simple.foldWithOptions_ fopts c q x (\x' r -> runInIO $ f x' r)

forEach :: (MonadUnliftIO m, MonadTrace env m, ToRow q, FromRow r) => Connection -> Query -> q -> (r -> m ()) -> m ()
forEach c q r f = spanning "forEach" $ do
  annotateBasics
  annotateQuery q
  withRunInIO $ \runInIO -> do
    Simple.forEach c q r (runInIO . f)

forEach_ :: (MonadUnliftIO m, MonadTrace env m, FromRow r) => Connection -> Query -> (r -> m ()) -> m ()
forEach_ c q f = spanning "forEach_" $ do
  annotateBasics
  annotateQuery q
  withRunInIO $ \runInIO -> do
    Simple.forEach_ c q (runInIO . f)

returning :: (MonadTrace env m, ToRow q, FromRow r) => Connection -> Query -> [q] -> m [r]
returning c q rs = spanningIO "returning" $ do
  annotateBasics
  annotateQuery q
  liftIO $ Simple.returning c q rs

foldWith :: (MonadUnliftIO m, MonadTrace env m, ToRow params) => RowParser row -> Connection -> Query -> params -> a -> (a -> row -> m a) -> m a
foldWith rp c q ps x f = spanning "foldWith" $ do
  annotateBasics
  annotateQuery q
  withRunInIO $ \runInIO -> do
    Simple.foldWith rp c q ps x (\x' r -> runInIO $ f x' r)

foldWithOptionsAndParser :: (MonadUnliftIO m, MonadTrace env m, ToRow params) => FoldOptions -> RowParser row -> Connection -> Query -> params -> a -> (a -> row -> m a) -> m a
foldWithOptionsAndParser fopts rp c q params x f = spanning "foldWithOptionsAndParser" $ do
  annotateBasics
  annotateQuery q
  withRunInIO $ \runInIO -> do
    Simple.foldWithOptionsAndParser fopts rp c q params x (\x' r -> runInIO $ f x' r)

foldWith_ :: (MonadUnliftIO m, MonadTrace env m) => RowParser r -> Connection -> Query -> a -> (a -> r -> m a) -> m a
foldWith_ rp c q x f = spanning "foldWith_" $ do
  annotateBasics
  annotateQuery q
  withRunInIO $ \runInIO -> do
    Simple.foldWith_ rp c q x (\x' r -> runInIO $ f x' r)

foldWithOptionsAndParser_ :: (MonadUnliftIO m, MonadTrace env m) => FoldOptions -> RowParser r -> Connection -> Query -> a -> (a -> r -> m a) -> m a
foldWithOptionsAndParser_ fopts rp c q x f = spanning "foldWithOptionsAndParser_" $ do
  annotateBasics
  annotateQuery q
  withRunInIO $ \runInIO -> do
    Simple.foldWithOptionsAndParser_ fopts rp c q x (\x' r -> runInIO $ f x' r)

forEachWith :: (MonadUnliftIO m, MonadTrace env m, ToRow q) => RowParser r -> Connection -> Query -> q -> (r -> m ()) -> m ()
forEachWith rp c q params f = spanning "forEachWith" $ do
  annotateBasics
  annotateQuery q
  withRunInIO $ \runInIO -> do
    Simple.forEachWith rp c q params (runInIO . f)

forEachWith_ :: (MonadUnliftIO m, MonadTrace env m) => RowParser r -> Connection -> Query -> (r -> m ()) -> m ()
forEachWith_ rp c q f = spanning "forEachWith_" $ do
  annotateBasics
  annotateQuery q
  withRunInIO $ \runInIO -> do
    Simple.forEachWith_ rp c q (runInIO . f)

returningWith :: (MonadTrace env m, ToRow q) => RowParser r -> Connection -> Query -> [q] -> m [r]
returningWith rp c q params = spanningIO "returningWith" $ do
  annotateBasics
  annotateQuery q
  liftIO $ Simple.returningWith rp c q params

execute :: (MonadTrace env m, ToRow q) => Connection -> Query -> q -> m Int64
execute c q r = spanningIO "execute" $ do
  annotateBasics
  annotateQuery q
  liftIO $ Simple.execute c q r

execute_ :: (MonadTrace env m) => Connection -> Query -> m Int64
execute_ c q = spanningIO "execute_" $ do
  annotateBasics
  annotateQuery q
  liftIO $ Simple.execute_ c q

executeMany :: (MonadTrace env m, ToRow q) => Connection -> Query -> [q] -> m Int64
executeMany c q rs = spanningIO "executeMany" $ do
  annotateBasics
  annotateQuery q
  liftIO $ Simple.executeMany c q rs

withTransaction :: (MonadUnliftIO m, MonadTrace env m) => Connection -> m a -> m a
withTransaction c m = spanning "withTransaction" $ do
  annotateBasics
  withRunInIO $ \runInIO -> 
    Simple.withTransaction c $ runInIO m

withSavepoint :: (MonadUnliftIO m, MonadTrace env m) => Connection -> m a -> m a
withSavepoint c m = spanning "withSavepoint" $ do
  annotateBasics
  withRunInIO $ \runInIO ->
    Simple.withSavepoint c $ runInIO m

begin :: (MonadTrace env m) => Connection -> m ()
begin c = spanningIO "begin" $ do
  annotateBasics
  liftIO $ Simple.begin c

commit :: (MonadTrace env m) => Connection -> m ()
commit c = spanningIO "commit" $ do
  annotateBasics
  liftIO $ Simple.commit c

rollback :: (MonadTrace env m) => Connection -> m ()
rollback c = spanningIO "rollback" $ do
  annotateBasics
  liftIO $ Simple.rollback c

formatMany :: (MonadTrace env m, ToRow q) => Connection -> Query -> [q] -> m ByteString
formatMany c q rs = spanningIO "formatMany" $ do
  annotateBasics
  liftIO $ Simple.formatMany c q rs

formatQuery :: (MonadTrace env m, ToRow q) => Connection -> Query -> q -> m ByteString
formatQuery c q r = spanningIO "formatQuery" $ do
  annotateBasics
  liftIO $ Simple.formatQuery c q r


-- Utils

annotateBasics :: MonadTrace env m => m ()
annotateBasics = do
  addSpanField serviceNameField ("postgresql" :: Text)
  addSpanField packageField ("postgresql-simple" :: Text)

annotateQuery :: (MonadTrace env m) => Query -> m ()
annotateQuery q = addSpanField databaseQueryField (show q)

-- annotateParams :: (MonadTrace env m) => q -> m ()
-- annotateParams q = addField databaseQueryField (show q)

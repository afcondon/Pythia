-- | Pandas FFI bindings for data manipulation
module Data.Pandas
  ( DataFrame
  , Series
  , readCsv
  , toRecords
  , describe
  , head
  , shape
  , columns
  , selectColumns
  , filterRows
  , groupBy
  , mean
  , sum
  , count
  , fromRecords
  ) where

import Prelude
import Effect (Effect)
import Data.Function.Uncurried (Fn1, Fn2, runFn1, runFn2)

-- | Pandas DataFrame handle
foreign import data DataFrame :: Type

-- | Pandas Series handle
foreign import data Series :: Type

-- | Read CSV file into DataFrame
foreign import readCsvImpl :: Fn1 String (Effect DataFrame)

readCsv :: String -> Effect DataFrame
readCsv path = runFn1 readCsvImpl path

-- | Convert DataFrame to array of records
foreign import toRecords :: forall a. DataFrame -> Array a

-- | Get descriptive statistics
foreign import describe :: DataFrame -> Effect String

-- | Get first n rows
foreign import headImpl :: Fn2 DataFrame Int DataFrame

head :: DataFrame -> Int -> DataFrame
head df n = runFn2 headImpl df n

-- | Get shape (rows, columns)
foreign import shape :: DataFrame -> { rows :: Int, cols :: Int }

-- | Get column names
foreign import columns :: DataFrame -> Array String

-- | Select specific columns
foreign import selectColumnsImpl :: Fn2 DataFrame (Array String) DataFrame

selectColumns :: DataFrame -> Array String -> DataFrame
selectColumns df cols = runFn2 selectColumnsImpl df cols

-- | Filter rows based on a condition (as string expression)
foreign import filterRowsImpl :: Fn2 DataFrame String DataFrame

filterRows :: DataFrame -> String -> DataFrame
filterRows df condition = runFn2 filterRowsImpl df condition

-- | Group by column(s)
foreign import groupByImpl :: Fn2 DataFrame (Array String) DataFrame

groupBy :: DataFrame -> Array String -> DataFrame
groupBy df cols = runFn2 groupByImpl df cols

-- | Calculate mean of numeric columns
foreign import mean :: DataFrame -> Effect (forall a. a)

-- | Calculate sum of numeric columns
foreign import sum :: DataFrame -> Effect (forall a. a)

-- | Count rows
foreign import count :: DataFrame -> Int

-- | Create DataFrame from array of records
foreign import fromRecordsImpl :: forall a. Fn1 (Array a) DataFrame

fromRecords :: forall a. Array a -> DataFrame
fromRecords recs = runFn1 fromRecordsImpl recs

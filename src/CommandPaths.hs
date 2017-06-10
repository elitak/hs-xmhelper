module CommandPaths where

import Prelude as P
import Data.Text

data Command = Rsync
             | TransmissionRemote
  deriving (Eq)

shortenIfWasntSubstituted :: String -> Text
shortenIfWasntSubstituted str
  | (x:xs) <- str, x == '@' = P.last $ splitOn (pack "/") (pack xs)
  | otherwise = pack str

-- NB the substitution variable names must be valid bash names (i.e. no dashes)
instance Show Command where
        show Rsync =  unpack . shortenIfWasntSubstituted $ "@rsync@/bin/rsync"
        show TransmissionRemote =  unpack . shortenIfWasntSubstituted $ "@transmisson@/bin/transmission-remote"


-- TODO
-- template haskell instead??
-- some internationalization lib?

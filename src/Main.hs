{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards #-}
module Main where

import Turtle
import Prelude hiding (lines, unlines, putStr, putStrLn, readFile)
import System.Environment
import Data.Maybe
import Data.Text (pack, unpack, intercalate, lines, unlines, strip, Text)
import Data.Text.IO (putStr, putStrLn)
--import Data.Foldable (toList)
import qualified Control.Foldl as Foldl

import StatusParser
import Text.Regex.Applicative

import TransmissionConfig
import Control.Monad

import CommandPaths

-- TODO remove this convenience func i added at the start of turtle porting
run :: Text -> [Text] -> Shell Line
run cmd args = inshell (intercalate " " $ [cmd] <> qargs) empty
    where qargs = [ "\"" <> t <> "\"" | t <- args ]

xm :: [Text] -> Shell Line
xm args = run (pack . show $ TransmissionRemote) args

xmOn :: Shell Integer -> [Text] -> Shell Line
xmOn ids args = do
    idList <- fold ids Foldl.list
    case idList of
        [] -> "Nothing to do; no torrent ids given."
        _  -> do
             let idts = map (pack . show) idList
             xm $ ["-t" <> intercalate "," idts] <> args

xmo args = do
    let op:ids = args
    xmOn (select $ map (read . unpack) ids) [op]

xmcheck args = do
    xmOn getFinishedIds ["-v"]

xmf args = do
    xmOn getFinishedIds ["-l"]

xmclean args = do
    TransmissionConfig{..} <- liftIO getConfig
    configDir <- liftIO getConfigDir
    let src = configDir <> "/torrents/"
    let dst = downloadDir <> "/_torrents"
    ec <- view $ shell (format (s%" -rP "%s%" "%s) (pack . show $ Rsync) src dst) empty
    -- TODO check rsync is in path
    -- TODO Guard here to make sure the above executed correctly
    -- (NB currently failure exits uncleanly because of attr preservation)
    xmOn getFinishedIds ["-r"]

-- TODO handle exception on parse returning Nothing
getFinishedIds :: Shell Integer
getFinishedIds = do
    lines <- parse <$> xm ["-l"]
    --lines <- parse <$> inshell "cat sample" empty
    case isFinished lines of
        True -> tid <$> pure lines
        False -> empty
    --TODO write like this--tid <$> isFinished <$> parse <$> inshell "cat sample" empty

    where
          body = tail . reverse . tail . reverse -- strip first and last line
          -- XXX fromJust should never fail since failed parse returns its own data constructor. still a better way to write in applicative context?
          parse = fromJust . (=~ statusLine) . unpack . lineToText
          isFinished StatusLine{..} = not faulty && done == DonePct 100
          --isFinished x@StatusLine{..}
          --  | not faulty && done == DonePct 100 = True
          --  | otherwise = False
          isFinished _ = False

xmtest args = do
    -- test whatever here
    --
    --ids <- getFinishedIds
    --return $ unsafeTextToLine . pack . show $ ids
    --
    run (format ("echo "%s%" -rP "%s%" "%s) (pack.show $ Rsync) "foo" "bar") empty
    --
    --return "test"

    -- TODO cmd to grab all non-stopped and dump as list of ids or names
    --  cmd to start|stop by name rather than id so persisted lists from the above can be used across reboots
    --  cmd to use -ph, -G -g easily to set get-rate on individual files in a torrent

-- TODO replace the lookup with template-haskell or something
calls :: [(Text, [Text] -> Shell Line)]
calls = [ ("xm"     , xm     ) -- shortcut for "transmission-remote"
        , ("xmo"    , xmo    ) -- Operate on listed ids. e.g. "xmo -v `seq 2 4`"
        , ("xmf"    , xmf    ) -- list Finished status lines (100% and not faulty)
        , ("xmcheck", xmcheck) -- verify finished torrents
        , ("xmclean", xmclean) -- use rsync to backup torrent files, then remove idle and finished torrents TODO: use cp -u instead?
        , ("xmtest" , xmtest) -- XXX test
        ]
    -- TODO cmd to grab all non-stopped and dump as list of ids or names
    --  cmd to start|stop by name rather than id so persisted lists from the above can be used across reboots
    --  cmd to use -ph, -G -g easily to set get-rate on individual files in a torrent
    --  `xma` alias which is `xm -t all`
    --  operate by regex matched on name:    xmr "some.*regex" -s

-- TODO: offer to create or intelligently know when to create multi-call links
main :: IO ()
main = do
    name <- getProgName >>= return . pack
    args <- getArgs >>= return . map pack
    let call = fromJust $ lookup name calls
    sh (call args >>= liftIO . putStrLn . lineToText)

-- TODO make interactive mode where i can do `stop 1` `ls active | stop`  and/or powershell-like piping of torrent ids

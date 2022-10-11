module Brain.Task.Ports exposing (..)

import Alien
import Json.Decode
import Json.Encode
import TaskPort



-- CACHE


fromCache : Alien.Tag -> Json.Decode.Decoder value -> TaskPort.Task (Maybe value)
fromCache tag decoder =
    TaskPort.call
        { function = "fromCache"
        , valueDecoder = Json.Decode.maybe decoder
        , argsEncoder = Json.Encode.string
        }
        (Alien.tagToString tag)


toCache : Alien.Tag -> Json.Encode.Value -> TaskPort.Task ()
toCache tag =
    let
        key =
            Alien.tagToString tag
    in
    TaskPort.call
        { function = "toCache"
        , valueDecoder = TaskPort.ignoreValue
        , argsEncoder = \v -> Json.Encode.object [ ( "key", Json.Encode.string key ), ( "value", v ) ]
        }

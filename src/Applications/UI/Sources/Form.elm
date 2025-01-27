module UI.Sources.Form exposing (..)

import Chunky exposing (..)
import Common exposing (boolFromString, boolToString)
import Conditional exposing (..)
import Dict.Ext as Dict
import Html exposing (Html, text)
import Html.Attributes exposing (for, name, placeholder, required, selected, type_, value)
import Html.Events exposing (onInput, onSubmit)
import List.Extra as List
import Material.Icons.Round as Icons
import Material.Icons.Types exposing (Coloring(..))
import Sources exposing (..)
import Sources.Services as Services
import UI.Kit exposing (ButtonType(..), select)
import UI.Navigation exposing (..)
import UI.Page as Page
import UI.Sources.Page as Sources
import UI.Sources.Types exposing (..)



-- 🌳


initialModel : Form
initialModel =
    { step = Where
    , context = defaultContext
    }


defaultContext : Source
defaultContext =
    { id = "CHANGE_ME_PLEASE"
    , data = Services.initialData defaultService
    , directoryPlaylists = True
    , enabled = True
    , service = defaultService
    }


defaultService : Service
defaultService =
    Dropbox



-- NEW


type alias Arguments =
    { onboarding : Bool }


new : Arguments -> Form -> List (Html Msg)
new args model =
    case model.step of
        Where ->
            newWhere args model

        How ->
            newHow model

        By ->
            newBy model


newWhere : Arguments -> Form -> List (Html Msg)
newWhere { onboarding } { context } =
    [ -----------------------------------------
      -- Navigation
      -----------------------------------------
      UI.Navigation.local
        [ ( Icon Icons.arrow_back
          , Label "Back to list" Hidden
            --
          , if onboarding then
                NavigateToPage Page.Index

            else
                NavigateToPage (Page.Sources Sources.Index)
          )
        ]

    -----------------------------------------
    -- Content
    -----------------------------------------
    , (\h ->
        form TakeStep
            [ UI.Kit.canisterForm h ]
      )
        [ UI.Kit.h2 "Where is your music stored?"

        -- Dropdown
        -----------
        , let
            contextServiceKey =
                Services.typeToKey context.service
          in
          Services.labels
            |> List.map
                (\( k, l ) ->
                    Html.option
                        [ value k, selected (contextServiceKey == k) ]
                        [ text l ]
                )
            |> select SelectService

        -- Button
        ---------
        , chunk
            [ "mt-10" ]
            [ UI.Kit.button
                IconOnly
                Bypass
                (Icons.arrow_forward 17 Inherit)
            ]
        ]
    ]


newHow : Form -> List (Html Msg)
newHow { context } =
    [ -----------------------------------------
      -- Navigation
      -----------------------------------------
      UI.Navigation.local
        [ ( Icon Icons.arrow_back
          , Label "Take a step back" Shown
          , PerformMsg TakeStepBackwards
          )
        ]

    -----------------------------------------
    -- Content
    -----------------------------------------
    , (\h ->
        form TakeStep
            [ chunk
                [ "text-left", "w-full" ]
                [ UI.Kit.canister h ]
            ]
      )
        [ UI.Kit.h3 "Where exactly?"

        -- Note
        -------
        , note context.service

        -- Fields
        ---------
        , let
            properties =
                Services.properties context.service

            dividingPoint =
                toFloat (List.length properties) / 2

            ( listA, listB ) =
                List.splitAt (ceiling dividingPoint) properties
          in
          chunk
            [ "flex", "pt-3" ]
            [ chunk
                [ "flex-grow", "pr-4" ]
                (List.map (renderProperty context) listA)
            , chunk
                [ "flex-grow", "pl-4" ]
                (List.map (renderProperty context) listB)
            ]

        -- Button
        ---------
        , chunk
            [ "mt-3", "text-center" ]
            [ UI.Kit.button
                IconOnly
                Bypass
                (Icons.arrow_forward 17 Inherit)
            ]
        ]
    ]


howNote : List (Html Msg) -> Html Msg
howNote =
    chunk
        [ "text-sm"
        , "italic"
        , "leading-normal"
        , "max-w-lg"
        , "mb-8"
        ]


newBy : Form -> List (Html Msg)
newBy { context } =
    [ -----------------------------------------
      -- Navigation
      -----------------------------------------
      UI.Navigation.local
        [ ( Icon Icons.arrow_back
          , Label "Take a step back" Shown
          , PerformMsg TakeStepBackwards
          )
        ]

    -----------------------------------------
    -- Content
    -----------------------------------------
    , (\h ->
        form AddSourceUsingForm
            [ UI.Kit.canisterForm h ]
      )
        [ UI.Kit.h2 "One last thing"
        , UI.Kit.label [] "What are we going to call this source?"

        -- Input
        --------
        , let
            nameValue =
                Dict.fetch "name" "" context.data
          in
          chunk
            [ "flex"
            , "max-w-md"
            , "mt-8"
            , "mx-auto"
            , "justify-center"
            , "w-full"
            ]
            [ UI.Kit.textField
                [ name "name"
                , onInput (SetFormData "name")
                , value nameValue
                ]
            ]

        -- Note
        -------
        , chunk
            [ "mt-16" ]
            (case context.service of
                AmazonS3 ->
                    corsWarning "CORS__S3"

                AzureBlob ->
                    corsWarning "CORS__Azure"

                AzureFile ->
                    corsWarning "CORS__Azure"

                Btfs ->
                    corsWarning "CORS__BTFS"

                Dropbox ->
                    []

                Google ->
                    []

                Ipfs ->
                    corsWarning "CORS__IPFS"

                WebDav ->
                    corsWarning "CORS__WebDAV"
            )

        -- Button
        ---------
        , UI.Kit.button
            Normal
            Bypass
            (text "Add source")
        ]
    ]


corsWarning : String -> List (Html Msg)
corsWarning id =
    [ chunk
        [ "text-sm", "flex", "items-center", "justify-center", "leading-snug", "opacity-50" ]
        [ UI.Kit.inlineIcon Icons.warning
        , inline
            [ "font-semibold" ]
            [ text "Make sure CORS is enabled" ]
        ]
    , chunk
        [ "text-sm", "leading-snug", "mb-8", "mt-1", "opacity-50" ]
        [ text "You can find the instructions over "
        , UI.Kit.link { label = "here", url = "about/cors/#" ++ id }
        ]
    ]



-- EDIT


edit : Form -> List (Html Msg)
edit { context } =
    [ -----------------------------------------
      -- Navigation
      -----------------------------------------
      UI.Navigation.local
        [ ( Icon Icons.arrow_back
          , Label "Go Back" Shown
          , PerformMsg ReturnToIndex
          )
        ]

    -----------------------------------------
    -- Content
    -----------------------------------------
    , (\h ->
        form EditSourceUsingForm
            [ chunk
                [ "text-left", "w-full" ]
                [ UI.Kit.canister h ]
            ]
      )
        [ UI.Kit.h3 "Edit source"

        -- Note
        -------
        , note context.service

        -- Fields
        ---------
        , let
            properties =
                Services.properties context.service

            dividingPoint =
                toFloat (List.length properties) / 2

            ( listA, listB ) =
                List.splitAt (ceiling dividingPoint) properties
          in
          chunk
            [ "flex", "pt-3" ]
            [ chunk
                [ "flex-grow", "pr-4" ]
                (List.map (renderProperty context) listA)
            , chunk
                [ "flex-grow", "pl-4" ]
                (List.map (renderProperty context) listB)
            ]

        -- Button
        ---------
        , chunk
            [ "mt-3", "text-center" ]
            [ UI.Kit.button
                Normal
                Bypass
                (text "Save")
            ]
        ]
    ]



-- PROPERTIES


renderProperty : Source -> Property -> Html Msg
renderProperty context property =
    chunk
        [ "mb-8" ]
        [ UI.Kit.label
            [ for property.key ]
            property.label

        --
        , if
            (property.placeholder == boolToString True)
                || (property.placeholder == boolToString False)
          then
            let
                bool =
                    context.data
                        |> Dict.fetch property.key property.placeholder
                        |> boolFromString
            in
            chunk
                [ "mt-2", "pt-1" ]
                [ UI.Kit.checkbox
                    { checked = bool
                    , toggleMsg =
                        bool
                            |> not
                            |> boolToString
                            |> SetFormData property.key
                    }
                ]

          else
            UI.Kit.textField
                [ name property.key
                , onInput (SetFormData property.key)
                , placeholder property.placeholder
                , required (property.label |> String.toLower |> String.contains "optional" |> not)
                , type_ (ifThenElse property.password "password" "text")
                , value (Dict.fetch property.key "" context.data)
                ]
        ]



-- ⚗️


form : Msg -> List (Html Msg) -> Html Msg
form msg html =
    slab
        Html.form
        [ onSubmit msg ]
        [ "flex"
        , "flex-grow"
        , "flex-shrink-0"
        , "text-center"
        ]
        [ UI.Kit.centeredContent html ]


note : Service -> Html Msg
note service =
    case service of
        AmazonS3 ->
            nothing

        AzureBlob ->
            nothing

        AzureFile ->
            nothing

        Btfs ->
            howNote
                [ inline [ "font-semibold" ] [ text "Diffuse will try to use the default local gateway" ]
                , text "."
                , lineBreak
                , text "If you would like to use another gateway, please provide it below."
                , lineBreak
                , text "This is basically the same as the IPFS implementation, just with a different prefix."
                ]

        Dropbox ->
            howNote
                [ inline
                    [ "font-semibold" ]
                    [ text "If you don't know what any of this is, "
                    , text "continue to the next screen."
                    ]
                , text " Changing the app key allows you to use your own Dropbox app."
                , text " Also, make sure you verified your email address on Dropbox,"
                , text " or this might not work."
                ]

        Google ->
            howNote
                [ inline
                    [ "font-semibold" ]
                    [ text "If you don't know what any of this is, "
                    , text "continue to the next screen."
                    ]
                , text " Changing the client stuff allows you to use your own Google OAuth client."
                , text " Disclaimer: "
                , text "The Google Drive API is fairly slow and limited, "
                , text "consider using a different service."
                ]

        Ipfs ->
            howNote
                [ inline [ "font-semibold" ] [ text "Diffuse will try to use the default local gateway" ]
                , text "."
                , lineBreak
                , text "If you would like to use another gateway, please provide it below."
                ]

        WebDav ->
            howNote
                [ inline
                    [ "font-semibold" ]
                    [ UI.Kit.inlineIcon Icons.warning
                    , text "This app requires a proper implementation of "
                    , UI.Kit.link
                        { label = "CORS"
                        , url = "https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS"
                        }
                    , text " on the server side."
                    ]
                , lineBreak
                , text " WebDAV servers usually don't implement"
                , text " CORS properly, if at all."
                , lineBreak
                , text " Some servers, like "
                , UI.Kit.link
                    { label = "this one"
                    , url = "https://github.com/hacdias/webdav"
                    }
                , text ", do. You can find the configuration for that server "
                , UI.Kit.link
                    { label = "here"
                    , url = "about/cors/#CORS__WebDAV"
                    }
                , text "."
                ]



-- RENAME


rename : Form -> List (Html Msg)
rename { context } =
    [ -----------------------------------------
      -- Navigation
      -----------------------------------------
      UI.Navigation.local
        [ ( Icon Icons.arrow_back
          , Label "Go Back" Shown
          , PerformMsg ReturnToIndex
          )
        ]

    -----------------------------------------
    -- Content
    -----------------------------------------
    , (\h ->
        form RenameSourceUsingForm
            [ UI.Kit.canisterForm h ]
      )
        [ UI.Kit.h2 "Name your source"

        -- Input
        --------
        , [ name "name"
          , onInput (SetFormData "name")
          , value (Dict.fetch "name" "" context.data)
          ]
            |> UI.Kit.textField
            |> chunky [ "max-w-md", "mx-auto" ]

        -- Button
        ---------
        , chunk
            [ "mt-10" ]
            [ UI.Kit.button
                Normal
                Bypass
                (text "Save")
            ]
        ]
    ]

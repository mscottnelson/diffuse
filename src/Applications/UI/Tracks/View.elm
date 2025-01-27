module UI.Tracks.View exposing (view)

import Chunky exposing (..)
import Color exposing (Color)
import Common exposing (Switch(..))
import Conditional exposing (ifThenElse)
import Html exposing (Html, text)
import Html.Attributes as A exposing (attribute, href, placeholder, style, tabindex, target, title, value)
import Html.Events as E exposing (onBlur, onClick, onInput)
import Html.Events.Extra.Mouse as Mouse
import Html.Ext exposing (onEnterKey)
import Html.Lazy exposing (..)
import Keyboard exposing (Key(..))
import Material.Icons.Round as Icons
import Material.Icons.Types exposing (Coloring(..))
import Maybe.Extra as Maybe
import Playlists exposing (Playlist)
import Tracks exposing (..)
import UI.Kit
import UI.Navigation exposing (..)
import UI.Page as Page
import UI.Playlists.Page
import UI.Queue.Page
import UI.Sources.Page as Sources
import UI.Tracks.Scene.Covers
import UI.Tracks.Scene.List
import UI.Tracks.Types exposing (..)
import UI.Types as UI exposing (..)



-- 🌳


type alias NavigationProperties =
    { bgColor : Maybe Color
    , favouritesOnly : Bool
    , grouping : Maybe Grouping
    , isOnIndexPage : Bool
    , pressedShift : Bool
    , scene : Scene
    , searchTerm : Maybe String
    , selectedPlaylist : Maybe Playlist
    , showVolumeSlider : Bool
    , volume : Float
    }



-- 🗺


view : Model -> Html UI.Msg
view model =
    let
        isOnIndexPage =
            model.page == Page.Index
    in
    chunk
        viewClasses
        [ lazy
            navigation
            { bgColor = model.extractedBackdropColor
            , favouritesOnly = model.favouritesOnly
            , grouping = model.grouping
            , isOnIndexPage = isOnIndexPage
            , pressedShift = List.member Shift model.pressedKeys
            , scene = model.scene
            , searchTerm = model.searchTerm
            , selectedPlaylist = model.selectedPlaylist
            , showVolumeSlider = model.showVolumeSlider
            , volume = model.eqSettings.volume
            }

        --
        , if List.isEmpty model.tracks.harvested then
            lazy4
                noTracksView
                (List.map Tuple.first model.processingContext)
                (List.length model.sources)
                (List.length model.tracks.harvested)
                (List.length model.favourites)

          else
            case model.scene of
                Covers ->
                    UI.Tracks.Scene.Covers.view
                        { bgColor = model.extractedBackdropColor
                        , cachedCovers = model.cachedCovers
                        , covers = model.covers.harvested
                        , darkMode = model.darkMode
                        , favouritesOnly = model.favouritesOnly
                        , infiniteList = model.infiniteList
                        , isVisible = isOnIndexPage
                        , nowPlaying = model.nowPlaying
                        , selectedCover = model.selectedCover
                        , selectedTrackIndexes = model.selectedTrackIndexes
                        , sortBy = model.sortBy
                        , sortDirection = model.sortDirection
                        , viewportHeight = model.viewport.height
                        , viewportWidth = model.viewport.width
                        }

                List ->
                    model.selectedPlaylist
                        |> Maybe.map .autoGenerated
                        |> Maybe.andThen
                            (\bool ->
                                if bool then
                                    Nothing

                                else
                                    Just model.dnd
                            )
                        |> UI.Tracks.Scene.List.view
                            { bgColor = model.extractedBackdropColor
                            , darkMode = model.darkMode
                            , height = model.viewport.height
                            , isTouchDevice = model.isTouchDevice
                            , isVisible = isOnIndexPage
                            , showAlbum = model.viewport.width >= 720
                            }
                            model.tracks.harvested
                            model.infiniteList
                            model.favouritesOnly
                            model.nowPlaying
                            model.searchTerm
                            model.sortBy
                            model.sortDirection
                            model.selectedTrackIndexes
        ]


viewClasses : List String
viewClasses =
    [ "flex"
    , "flex-col"
    , "flex-grow"
    , "relative"
    ]


navigation : NavigationProperties -> Html UI.Msg
navigation { bgColor, favouritesOnly, grouping, isOnIndexPage, pressedShift, scene, searchTerm, selectedPlaylist, showVolumeSlider, volume } =
    let
        tabindex_ =
            ifThenElse isOnIndexPage 0 -1
    in
    chunk
        [ "relative", "sm:flex" ]
        [ -----------------------------------------
          -- Part 1
          -----------------------------------------
          chunk
            [ "border-b"
            , "border-r"
            , "border-gray-300"
            , "flex"
            , "flex-grow"
            , "h-12"
            , "mt-px"
            , "px-1"
            , "overflow-hidden"
            , "relative"
            , "text-gray-600"

            -- Responsive
            -------------
            , "sm:h-auto"
            , "sm:px-0"

            -- Dark mode
            ------------
            , "dark:border-base01"
            , "dark:text-base04"
            ]
            [ -- Input
              --------
              slab
                Html.input
                [ attribute "autocorrect" "off"
                , attribute "autocapitalize" "none"
                , onBlur (TracksMsg Search)
                , onEnterKey (TracksMsg Search)
                , onInput (TracksMsg << SetSearchTerm)
                , placeholder "Search"
                , tabindex tabindex_
                , value (Maybe.withDefault "" searchTerm)
                ]
                [ "bg-transparent"
                , "border-none"
                , "flex-grow"
                , "h-full"
                , "min-w-0"
                , "ml-1"
                , "mt-px"
                , "outline-none"
                , "pl-8"
                , "pr-2"
                , "pt-px"
                , "text-base02"
                , "text-sm"
                , "w-full"

                -- Dark mode
                ------------
                , "dark:text-base06"
                ]
                []

            -- Search icon
            --------------
            , chunk
                [ "absolute"
                , "bottom-0"
                , "flex"
                , "items-center"
                , "left-0"
                , "ml-3"
                , "mt-px"
                , "pl-1"
                , "top-0"
                , "z-0"

                -- Responsive
                -------------
                , "sm:pl-0"
                ]
                [ Icons.search 16 Inherit ]

            -- Actions
            ----------
            , chunk
                [ "flex"
                , "items-center"
                , "mr-3"
                , "mt-px"
                , "pt-px"
                , "space-x-4"

                -- Responsive
                -------------
                , "sm:space-x-2"
                ]
                [ -- 1
                  case searchTerm of
                    Just _ ->
                        brick
                            [ onClick (TracksMsg ClearSearch)
                            , title "Clear search"
                            ]
                            [ "cursor-pointer"
                            , "mt-px"
                            ]
                            [ Icons.clear 16 Inherit ]

                    Nothing ->
                        nothing

                -- 2
                , brick
                    [ onClick (TracksMsg ToggleFavouritesOnly)
                    , title "Toggle favourites-only"
                    ]
                    [ "cursor-pointer" ]
                    [ if favouritesOnly then
                        Icons.favorite 16 (Color UI.Kit.colorKit.base08)

                      else
                        Icons.favorite_border 16 Inherit
                    ]

                -- 3
                , case scene of
                    Covers ->
                        brick
                            [ attribute "title" "Switch to list view"
                            , List
                                |> ChangeScene
                                |> TracksMsg
                                |> onClick
                            ]
                            [ "ml-6"
                            , "mr-px"
                            , "cursor-pointer"
                            ]
                            [ chunk
                                [ "pl-1" ]
                                [ Icons.notes 18 Inherit ]
                            ]

                    List ->
                        brick
                            [ attribute "title" "Switch to cover view"
                            , Covers
                                |> ChangeScene
                                |> TracksMsg
                                |> onClick
                            ]
                            [ "cursor-pointer"
                            , "mr-px"
                            ]
                            [ chunk
                                [ "pl-1" ]
                                [ Icons.burst_mode 20 Inherit ]
                            ]

                -- 4
                , brick
                    [ Mouse.onClick (TracksMsg << ShowViewMenu grouping)
                    , title "View settings"
                    ]
                    [ "cursor-pointer" ]
                    [ Icons.more_vert 16 Inherit ]

                -- 5
                , case selectedPlaylist of
                    Just playlist ->
                        brick
                            [ onClick DeselectPlaylist
                            , title "Deactivate playlist"

                            --
                            , bgColor
                                |> Maybe.withDefault UI.Kit.colorKit.base01
                                |> Color.toCssString
                                |> style "background-color"
                            ]
                            [ "antialiased"
                            , "cursor-pointer"
                            , "duration-500"
                            , "font-bold"
                            , "leading-none"
                            , "px-1"
                            , "py-1"
                            , "rounded"
                            , "truncate"
                            , "text-white-90"
                            , "text-xxs"
                            , "transition"

                            -- Dark mode
                            ------------
                            , "dark:text-white-60"
                            ]
                            [ chunk
                                [ "px-px", "pt-px" ]
                                [ text playlist.name ]
                            ]

                    Nothing ->
                        nothing
                ]
            ]
        , -----------------------------------------
          -- Part 2
          -----------------------------------------
          UI.Navigation.localWithTabindex
            tabindex_
            [ ( Icon Icons.waves
              , Label "Playlists" Hidden
              , if pressedShift then
                    PerformMsg AssistWithSelectingPlaylist

                else
                    NavigateToPage (Page.Playlists UI.Playlists.Page.Index)
              )
            , ( Icon Icons.schedule
              , Label "Queue" Hidden
              , if pressedShift then
                    PerformMsg (ChangeUrlUsingPage <| Page.Queue UI.Queue.Page.History)

                else
                    NavigateToPage (Page.Queue UI.Queue.Page.Index)
              )
            , ( if volume == 0 then
                    Icon Icons.volume_off

                else if volume < 0.5 then
                    Icon Icons.volume_down

                else
                    Icon Icons.volume_up
              , Label "Volume" Hidden
              , if pressedShift then
                    if volume == 0 then
                        PerformMsg (AdjustVolume 0.5)

                    else
                        PerformMsg (AdjustVolume 0)

                else
                    PerformMsg (ToggleVolumeSlider <| ifThenElse showVolumeSlider Off On)
              )
            ]
        , -----------------------------------------
          -- Part 3
          -----------------------------------------
          if showVolumeSlider then
            chunk
                [ "absolute"
                , "bg-white"
                , "px-4"
                , "py-3"
                , "right-0"
                , "rounded-bl"
                , "shadow-lg"
                , "top-full"
                , "z-30"

                -- Dark mode
                ------------
                , "dark:bg-darkest-hour"
                , "dark:shadow-[rgba(0,0,0,.175)]"
                ]
                [ chunk
                    [ "leading-[0px]"
                    , "my-1"
                    , "pt-px"
                    , "text-[0px]"
                    ]
                    [ slab
                        Html.input
                        [ A.type_ "range"
                        , A.min "0"
                        , A.max "1"
                        , A.step "0.0125"
                        , A.value (String.fromFloat volume)

                        --
                        , E.onBlur SaveEnclosedUserData
                        , E.onInput (String.toFloat >> Maybe.unwrap Bypass AdjustVolume)
                        ]
                        [ "range-slider" ]
                        []
                    ]
                ]

          else
            nothing
        ]


noTracksView : List String -> Int -> Int -> Int -> Html UI.Msg
noTracksView processingContext amountOfSources amountOfTracks _ =
    chunk
        [ "no-tracks-view"

        --
        , "flex"
        , "flex-grow"
        ]
        [ UI.Kit.centeredContent
            [ if List.length processingContext > 0 then
                message "Processing Tracks"

              else if amountOfSources == 0 then
                chunk
                    [ "flex"
                    , "flex-wrap"
                    , "items-start"
                    , "justify-center"
                    , "px-3"
                    ]
                    [ -----------------------------------------
                      -- Add
                      -----------------------------------------
                      inline
                        [ "mb-4"
                        , "mx-2"
                        , "whitespace-nowrap"
                        ]
                        [ UI.Kit.buttonLink
                            (Sources.NewOnboarding
                                |> Page.Sources
                                |> Page.toString
                            )
                            UI.Kit.Filled
                            (buttonContents
                                [ UI.Kit.inlineIcon Icons.add
                                , text "Add some music"
                                ]
                            )
                        ]

                    -----------------------------------------
                    -- Demo
                    -----------------------------------------
                    , inline
                        [ "mb-4"
                        , "mx-2"
                        , "whitespace-nowrap"
                        ]
                        [ UI.Kit.buttonWithColor
                            UI.Kit.Gray
                            UI.Kit.Normal
                            InsertDemo
                            (buttonContents
                                [ UI.Kit.inlineIcon Icons.music_note
                                , text "Insert demo"
                                ]
                            )
                        ]

                    -----------------------------------------
                    -- How
                    -----------------------------------------
                    , inline
                        [ "mb-4"
                        , "mx-2"
                        , "whitespace-nowrap"
                        ]
                        [ UI.Kit.buttonWithOptions
                            Html.a
                            [ href "about/"
                            , target "_blank"
                            ]
                            UI.Kit.Gray
                            UI.Kit.Normal
                            Nothing
                            (buttonContents
                                [ UI.Kit.inlineIcon Icons.help
                                , text "More info"
                                ]
                            )
                        ]
                    ]

              else if amountOfTracks == 0 then
                message "No tracks found"

              else
                message "No sources available"
            ]
        ]


buttonContents : List (Html UI.Msg) -> Html UI.Msg
buttonContents =
    inline
        [ "flex"
        , "items-center"
        , "leading-0"
        ]


message : String -> Html UI.Msg
message m =
    chunk
        [ "border-b-2"
        , "border-current-color"
        , "text-sm"
        , "font-semibold"
        , "leading-snug"
        , "pb-1"
        ]
        [ text m ]

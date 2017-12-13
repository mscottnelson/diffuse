module Tracks.Collection.Internal.Harvest exposing (harvest)

import List.Extra as List
import Maybe.Extra as Maybe
import Tracks.Types exposing (..)


-- 🍯


harvest : Parcel -> Parcel
harvest ( model, collection ) =
    let
        harvested =
            case model.searchResults of
                Just [] ->
                    []

                Just trackIds ->
                    collection.arranged
                        |> List.foldl harvester ( [], trackIds )
                        |> Tuple.first

                Nothing ->
                    collection.arranged

        filters =
            [ --
              -- Favourites / Missing
              if model.favouritesOnly then
                Tuple.first >> .isFavourite >> (==) True
              else if Maybe.isJust model.selectedPlaylist then
                always True
              else
                Tuple.first >> .isMissing >> (==) False

            --
            -- Playlists
            , case model.selectedPlaylist of
                Just playlist ->
                    case playlist.autoGenerated of
                        True ->
                            \( _, t ) ->
                                t.path
                                    |> String.split "/"
                                    |> List.head
                                    |> Maybe.withDefault ""
                                    |> (==) playlist.name

                        False ->
                            \( i, _ ) ->
                                Maybe.isJust i.indexInPlaylist

                Nothing ->
                    always True
            ]

        theFilter =
            \x ->
                List.foldl
                    (\filter bool ->
                        if bool == True then
                            filter x
                        else
                            bool
                    )
                    True
                    filters
    in
        harvested
            |> List.filter theFilter
            |> List.indexedMap (\idx tup -> Tuple.mapFirst (\i -> { i | indexInList = idx }) tup)
            |> (\h -> { collection | harvested = h })
            |> (,) model


harvester :
    IdentifiedTrack
    -> ( List IdentifiedTrack, List TrackId )
    -> ( List IdentifiedTrack, List TrackId )
harvester ( i, t ) ( acc, trackIds ) =
    case List.findIndex ((==) t.id) trackIds of
        Just idx ->
            ( acc ++ [ ( i, t ) ]
            , List.removeAt idx trackIds
            )

        Nothing ->
            ( acc
            , trackIds
            )
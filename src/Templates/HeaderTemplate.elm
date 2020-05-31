module Templates.HeaderTemplate exposing (..)

import Entities exposing (..)
import Faction exposing (..)
import Html exposing (Html, button, div, img, span, text)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Types exposing (Msg(..))
import Troops exposing (..)


testRevenueList : List (String, Float)
testRevenueList =
    [ ("Castles:", 2.5 ), ( "Village:", 1.9 ), ( "Army:", -3.3 ) ]


testTroopList : List Troop
testTroopList = [{amount = 50, troopType = Troops.Sword}, {amount = 30, troopType = Troops.Spear}, {amount = 30, troopType = Troops.Archer}, {amount = 11, troopType = Troops.Knight}]

generateHeaderTemplate : Lord ->  Html Msg
generateHeaderTemplate lord =
    let
        value = revenueToSpan ("", List.foldr (+) 0 (List.map Tuple.second testRevenueList))
    in
    div [Html.Attributes.class "page-header"] [
        div [Html.Attributes.class "page-turn-header"] [
            div [Html.Attributes.class "page-turn-handler-header"] [
                div [Html.Attributes.class "page-turn-button"] [
                    span [ onClick EndRound ] [Html.text "End turn"]
                ]
            ]
            , div [Html.Attributes.class "page-turn-date-header"] [
                span [Html.Attributes.class "page-header-span"] [ Html.text "January 1077 AD" ]
            ]
        ]
        ,div [Html.Attributes.class "page-gold-header"] [
            img [src  "./assets/images/ducats_icon.png", Html.Attributes.class "page-header-images"] []
            , div [Html.Attributes.class "tooltip"] [
                span [Html.Attributes.class "page-header-span"] [
                     Html.text (String.fromInt lord.gold ++ " Ducats") 
                     , value
                ]
                , div [Html.Attributes.class "tooltiptext gold-tooltip"] [
                    span [] [Html.text "Monthly revenue" ]
                    , div [] (List.map revenuesToTemplate testRevenueList)
                    , div [Html.Attributes.class "revenue-result-container"] [
                        revenueToSpan ("Revenue",  List.foldr (+) 0 (List.map Tuple.second testRevenueList))
                    ]
                ]
            ]
        ]
        , div [Html.Attributes.class "page-troop-header"] [
            img [src  "./assets/images/troop_icon.png", Html.Attributes.class "page-header-images"] []
            , div [Html.Attributes.class "tooltip"] [
                span [Html.Attributes.class "page-header-span"] [ Html.text (String.fromInt (List.foldr (+) 0 (List.map (\x -> x.amount) lord.entity.army)) ++ " Troops") ]
                , div [Html.Attributes.class "tooltiptext troop-tooltip"] [
                    span [] [Html.text "Current Troops" ]
                    , div [ Html.Attributes.class "troop-container-header troop-container"] [
                        div [] []
                        , span [] [Html.text "In the Army"]
                        , span [] [Html.text "Stantioned"]
                    ]
                    , div [] (List.map2 generateTroopTooltip lord.entity.army (sumTroopsFromSettlements lord.land troopTypeList))
                ]
            ]
        ]
        , div [Html.Attributes.class "page-settings-header"] [
            div [onClick ShowSettlement, Html.Attributes.class "page-setting-container tooltip"] [
                    img [src  "./assets/images/audio_on_icon.png", Html.Attributes.class "page-image-settings"] []
                    , div [Html.Attributes.class "tooltip"] [
                        span [Html.Attributes.class "tooltiptext settings-tooltip"] [ Html.text "Mute or unmute the gamesounds" ]
                    ]
                ]
            , div [ Html.Attributes.class "page-settings-grid" ]
                [ div [ Html.Attributes.class "page-setting-container tooltip" ]
                    [ img [ src "./assets/images/save_icon.png", Html.Attributes.class "page-image-settings" ] []
                    , div [ Html.Attributes.class "tooltip" ]
                        [ span [ Html.Attributes.class "tooltiptext settings-tooltip" ] [ Html.text "Save the game as a file" ]
                        ]
                    ]
                ]
        ]
    ]

-- REVENUE WIRD AUSGELAGERT
------------------------------------------------------------------------------------------------------------------------------------

revenuesToTemplate : (String, Float)-> Html Msg
revenuesToTemplate rev =
            div [Html.Attributes.class "revenue-container"] [ revenueToSpan rev]

revenueToSpan : (String, Float)-> Html Msg
revenueToSpan (name, value) =
    if value > 0 then
        span [ Html.Attributes.class "positive-income" ] [ Html.text (name ++ "  +" ++ String.fromFloat value ++ " Ducats") ]

    else
        span [ Html.Attributes.class "negative-income" ] [ Html.text (name ++ " " ++ String.fromFloat value ++ " Ducats") ]



-- Troop WIRD AUSGELAGERT (Sobald MSG ausgelagert ist)
------------------------------------------------------------------------------------------------------------------------------------

generateTroopTooltip : Troop -> Troop -> Html Msg
generateTroopTooltip aT sT = 
        div [Html.Attributes.class "troop-container"] [
            img [src  ("./assets/images/" ++ String.toLower (Troops.troopName aT.troopType) ++ "_icon.png")] []
            ,span [] [Html.text (String.fromInt aT.amount ++ "  " ++ Troops.troopName aT.troopType) ]
            ,span [] [Html.text (String.fromInt sT.amount ++ "  " ++ Troops.troopName sT.troopType) ]
        ]


sumSettlementsTroops : List Settlement -> List Troop
sumSettlementsTroops settle =
        case settle of 
            [] ->
                []
            
            (x :: xs) ->
                List.append x.entity.army (sumSettlementsTroops xs)


sumTroopsFromSettlements : List Settlement -> List TroopType -> List Troop
sumTroopsFromSettlements settel troops = 
            case troops of
                [] -> 
                    []

                (y :: ys) ->
                    {amount = List.foldr (\t v-> t.amount + v) 0 (List.filter (\ x -> x.troopType == y) (sumSettlementsTroops settel)), troopType = y} :: sumTroopsFromSettlements settel ys

module Templates.HeaderTemplate exposing (..)

import DateExt
import Dict
import DictExt
import Entities
import Entities.Model
import Html exposing (Html, div, img, input, span, text)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Msg
import Templates.HelperTemplate as Helper
import Troops



-- header interface component
--------------------------------------------------------


generateHeaderTemplate : Int -> Entities.Model.Lord -> DateExt.Date -> Html Msg.Msg
generateHeaderTemplate vol lord date =
    div [ Html.Attributes.class "page-header" ]
        [ div [ Html.Attributes.class "page-turn-header" ] (headerTurnTemplate date)
        , div [ Html.Attributes.class "page-gold-header" ] (headerGoldTemplate lord)
        , div [ Html.Attributes.class "page-troop-header" ] (headerTroopTemplate lord)
        , div [ Html.Attributes.class "page-settings-header" ] (headerSettingsTemplate vol)
        ]



-- turn button component
--------------------------------------------------------


headerTurnTemplate : DateExt.Date -> List (Html Msg.Msg)
headerTurnTemplate date =
    [ div [ Html.Attributes.class "page-turn-handler-header" ]
        [ div [ Html.Attributes.class "page-turn-button", onClick Msg.EndRound ]
            [ span [] [ Html.text "End turn" ] ]
        ]
    , div [ Html.Attributes.class "page-turn-date-header" ]
        [ span [ Html.Attributes.class "page-header-span" ] [ Html.text (DateExt.showDate date) ]
        ]
    ]



-- gold component
--------------------------------------------------------


headerGoldTemplate : Entities.Model.Lord -> List (Html Msg.Msg)
headerGoldTemplate lord =
    [ img [ onClick (Msg.EndGame True), src "./assets/images/general/ducats_icon.png", Html.Attributes.class "page-header-images" ] []
    , div [ Html.Attributes.class "tooltip" ]
        [ span [ Html.Attributes.class "page-header-span" ]
            [ Html.text (Helper.roundDigits lord.gold 2 ++ " Ducats")
            , revenueToSpan ( "", List.foldr (+) 0 (List.map Tuple.second (lordToRevenues lord)) )
            ]
        , div [ Html.Attributes.class "tooltiptext gold-tooltip" ]
            [ span [] [ Html.text "Monthly revenue" ]
            , div [] (List.map revenuesToTemplate (lordToRevenues lord))
            , div [ Html.Attributes.class "revenue-result-container" ]
                [ revenueToSpan ( "Revenue", List.foldr (+) 0 (List.map Tuple.second (lordToRevenues lord)) )
                ]
            ]
        ]
    ]



-- troop component
--------------------------------------------------------


headerTroopTemplate : Entities.Model.Lord -> List (Html Msg.Msg)
headerTroopTemplate lord =
    let
        lordSettlementTroops =
            Entities.sumLordSettlementTroops lord
    in
    [ img [ src "./assets/images/troops/troop_icon.png", Html.Attributes.class "page-header-images" ] []
    , div [ Html.Attributes.class "tooltip" ]
        [ span [ Html.Attributes.class "page-header-span" ] [ Html.text (String.fromInt (Dict.foldl (\k v r -> v + r) 0 lord.entity.army) ++ " Troops") ]
        , div [ Html.Attributes.class "tooltiptext troop-tooltip" ]
            [ span [] [ Html.text "Current Troops" ]
            , div [ Html.Attributes.class "troop-container-header troop-container" ]
                [ div [] []
                , span [] [ Html.text "In the Army" ]
                , span [] [ Html.text "Stantioned" ]
                ]
            , div []
                (DictExt.foldlOverKeys
                    (\k v r ->
                        case Dict.get k lordSettlementTroops of
                            Nothing ->
                                generateTroopTooltip (Troops.intToTroopType k) v 0 :: r

                            Just amount ->
                                generateTroopTooltip (Troops.intToTroopType k) v amount :: r
                    )
                    (\k r -> generateTroopTooltip (Troops.intToTroopType k) 0 0 :: r)
                    []
                    lord.entity.army
                    Troops.troopKeyList
                )
            ]
        ]
    , div [ Html.Attributes.class "troop-info-icon" ]
        [ span [ onClick (Msg.TroopAction Msg.TroopActionMsg) ] [ Html.text "Disband troops" ] ]
    ]


generateTroopTooltip : Troops.TroopType -> Int -> Int -> Html Msg.Msg
generateTroopTooltip aT aAmount sAmount =
    div [ Html.Attributes.class "troop-container" ]
        [ img [ src ("./assets/images/troops/" ++ String.toLower (Troops.troopName aT) ++ ".png") ] []
        , span [] [ Html.text (String.fromInt aAmount ++ "  " ++ Troops.troopName aT) ]
        , span [] [ Html.text (String.fromInt sAmount ++ "  " ++ Troops.troopName aT) ]
        ]



-- settings component
--------------------------------------------------------


headerSettingsTemplate : Int -> List (Html Msg.Msg)
headerSettingsTemplate vol =
    [ div [ Html.Attributes.class "page-setting-container tooltip" ]
        [ img [ src "./assets/images/general/audio_on_icon.png", Html.Attributes.class "page-image-settings" ] []
        , div [ Html.Attributes.class "tooltiptext sound-tooltip" ]
            [ input [ Html.Attributes.type_ "range", Html.Attributes.min "0", Html.Attributes.max "100", Html.Attributes.value (String.fromInt vol), Html.Events.onInput resolveOnChangeMsg ] []
            , div [ Html.Attributes.style "text-align" "center" ]
                [ span [] [ Html.text ("Current volume: " ++ String.fromInt vol ++ "%") ] ]
            ]
        ]
    , div [ Html.Attributes.class "page-settings-grid" ]
        [ div [ onClick (Msg.EventAction Msg.SwitchEventView), Html.Attributes.class "page-setting-container tooltip" ]
            [ img [ src "./assets/images/general/event.png", Html.Attributes.class "page-image-settings" ] []
            , div [ Html.Attributes.class "tooltip" ]
                [ span [ Html.Attributes.class "tooltiptext event-tooltip" ] [ Html.text "Hide / Show the event logs" ]
                ]
            ]
        ]
    ]



-- helper functions for the components
--------------------------------------------------------


lordToRevenues : Entities.Model.Lord -> List ( String, Float )
lordToRevenues l =
    [ ( "Settlements:", Entities.sumSettlementsIncome l.land ), ( "Armies:", Entities.sumTroopWages (Entities.sumLordTroops l) * -1 ) ]


revenuesToTemplate : ( String, Float ) -> Html Msg.Msg
revenuesToTemplate rev =
    div [ Html.Attributes.class "revenue-container" ] [ revenueToSpan rev ]


revenueToSpan : ( String, Float ) -> Html Msg.Msg
revenueToSpan ( name, value ) =
    if value > 0 then
        span [ Html.Attributes.class "positive-income" ] [ Html.text (name ++ "  +" ++ Helper.roundDigits value 2 ++ " Ducats") ]

    else
        span [ Html.Attributes.class "negative-income" ] [ Html.text (name ++ " " ++ Helper.roundDigits value 2 ++ " Ducats") ]


resolveOnChangeMsg : String -> Msg.Msg
resolveOnChangeMsg str =
    Msg.MenueAction (Msg.ChangeVolume (Maybe.withDefault 0 (String.toInt str)))

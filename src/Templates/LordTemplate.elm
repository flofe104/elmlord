module Templates.LordTemplate exposing (..)

import Dict
import Entities
import Html exposing (Html, div, img, span, text)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Templates.HelperTemplate as Helper
import Troops
import Types


{-| Returns the layout for the lord modal (View [Lord-Name])

    @param {Lord}: Takes the chosen Lord

-}
generateLordTemplate : Entities.Lord -> Html Types.Msg
generateLordTemplate l =
    div [ Html.Attributes.class "modal-background" ]
        [ div [ Html.Attributes.class "lord-modal" ]
            [ div [ Html.Attributes.class "settlement-modal-close-container" ]
                [ div [ onClick Types.CloseModal, Html.Attributes.class "settlement-modal-close-btn lord-modal-close-btn" ]
                    [ span [] [ Html.text "X" ]
                    ]
                ]
            , div [ Html.Attributes.class "lord-title" ]
                [ span [] [ Html.text l.entity.name ]
                ]
            , div [ Html.Attributes.class "lord-image" ]
                [ img [ src ("./assets/images/profiles/" ++ Entities.factionToImage l.entity.faction), Html.Attributes.class "box-shadow" ] []
                ]
            , div [ Html.Attributes.class "lord-stats" ]
                [ div [ Html.Attributes.class "lord-data box-shadow" ]
                    [ img [ src "./assets/images/general/ducats_icon.png" ] []
                    , span [] [ Html.text ("Gold: " ++ String.fromFloat l.gold) ]
                    ]
                , div [ Html.Attributes.class "lord-data box-shadow" ]
                    [ img [ src "./assets/images/map/Castle.png" ] []
                    , span [] [ Html.text ("Settlements: " ++ String.fromInt (List.length l.land)) ]
                    ]
                , div [ Html.Attributes.class "lord-troops box-shadow" ]
                    (div [ Html.Attributes.class "lord-troop-header" ]
                        [ span [] [ Html.text "Current-Army" ] ]
                        :: Dict.foldr (\k v r -> Helper.troopToHtml (Troops.intToTroopType k) v "lord-troop-container" :: r) [] l.entity.army
                    )
                ]
            ]
        ]

module Templates.StartTemplate exposing (..)

import Entities exposing (validatePlayerName)
import Html exposing (Html, button, div, img, input, span, text)
import Html.Attributes as HtmlAttr
import Html.Events exposing (onClick, onInput)
import List exposing (..)
import Msg
import OperatorExt
import String exposing (..)



-- Starts the game with the menue selection


startMenuTemplate : List (Html Msg.Msg)
startMenuTemplate =
    [ div [ HtmlAttr.class "start-logo-container" ] [ img [ HtmlAttr.src "./assets/images/general/logo.png" ] [] ]
    , div [ HtmlAttr.class "start-container" ]
        [ div [ HtmlAttr.class "start-header" ]
            [ span [ HtmlAttr.class "start-header-text" ] [ Html.text "Welcome mylord, what is your decision?" ] ]
        , div [ HtmlAttr.class "start-actions" ]
            [ div [] [ button [ onClick (Msg.MenueAction Msg.SetCampaingn), HtmlAttr.class "start-buttons" ] [ span [] [ Html.text "Start Campaign" ] ] ]
            , div [] [ button [ onClick (Msg.MenueAction Msg.ShowDocumentation), HtmlAttr.class "start-buttons" ] [ span [] [ Html.text "Documentation" ] ] ]
            , div [] [ button [ onClick (Msg.MenueAction Msg.ShowCredits), HtmlAttr.class "start-buttons" ] [ span [] [ Html.text "Credits" ] ] ]
            ]
        ]
    ]


startCampaign : String -> List (Html Msg.Msg)
startCampaign v =
    [ div [ HtmlAttr.class "start-logo-container" ] [ img [ HtmlAttr.src "./assets/images/general/logo.png" ] [] ]
    , div [ HtmlAttr.class "campaign-container" ]
        [ div [ HtmlAttr.class "start-header" ]
            [ span [ HtmlAttr.class "start-header-text" ] [ Html.text "M'lord, what is your name?" ] ]
        , div [ HtmlAttr.class "campaign-actions" ]
            [ div [ HtmlAttr.class "campaign-name-container" ]
                [ span [ HtmlAttr.class "campaign-name" ] [ Html.text "Name:" ]
                , input [ HtmlAttr.class "campaign-input", HtmlAttr.value v, onInput resolveOnChangeMsg ] []
                ]
            , div [ HtmlAttr.style "text-align" "center" ]
                [ generateInputMsg v
                ]
            , div [ HtmlAttr.class "campaign-buttons-container" ]
                [ div []
                    [ button
                        [ onClick (Msg.MenueAction (Msg.StartGame v))
                        , HtmlAttr.class (OperatorExt.ternary (Entities.validatePlayerName v || v == "") "start-buttons start-campaign-button troop-disabled-button" "start-buttons start-campaign-button")
                        , HtmlAttr.disabled (Entities.validatePlayerName v || v == "")
                        ]
                        [ span [] [ Html.text "Start Campaign" ] ]
                    ]
                ]
            ]
        , div [] [ button [ onClick (Msg.MenueAction Msg.ShowMenue), HtmlAttr.class "back-btn" ] [ span [] [ Html.text "Back" ] ] ]
        ]
    ]


resolveOnChangeMsg : String -> Msg.Msg
resolveOnChangeMsg str =
    Msg.MenueAction (Msg.ChangeName str)


generateInputMsg : String -> Html Msg.Msg
generateInputMsg str =
    OperatorExt.ternary (validatePlayerName str || str == "")
        (span [ HtmlAttr.class "error-msg" ] [ Html.text "Invalid name, please take another name!" ])
        (span [] [])

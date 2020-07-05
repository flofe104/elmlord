module Templates.EventTemplate exposing (..)

import Event
import Html exposing (Html, button, div, span, text)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import OperatorExt
import Types


{-| Returns the layout for the map actions, in dependence to the chosen point (in the model)

    @param {Maybe Point}: Takes the point that is currently chosen point (at the start no point is chosen, therefore Maybe)
    @param {MapDrawer.MapClickAction}: Takes a dict with all possible actions

-}
generateEventOverview : Event.EventState -> Html Types.Msg
generateEventOverview event =
    if event.state then
        div [ Html.Attributes.class "event-logs" ]
            [ div [ Html.Attributes.class "event-logs-header" ]
                [ span [] [ Html.text "Events" ]
                ]
            , div [ ] [ 
                button [onClick (Types.EventAction Types.ClearEvents)] [Html.text "Clear events"]
            ]
            , div [ Html.Attributes.class "event-logs-body" ] (List.map generateEventComponent event.events)
            ]

    else
        div [] []


{-| Function for map, that displays a button for each possible action

    @param {Types.MapTileMsg}: Takes the action type, that the button sends, when it gets clicked

-}
generateEventComponent : Event.Event -> Html Types.Msg
generateEventComponent e =
    div [ Html.Attributes.class ("event-logs-component " ++ OperatorExt.ternary (e.eventType == Event.Important) "important-log" "minor-log") ]
        [ div [] [ span [] [ Html.text e.header ] ]
        , div [ onClick (Types.EventAction (Types.DeleteEvent e.index)), Html.Attributes.class "event-logs-close" ] [ Html.text "x" ]
        , div [] [ span [] [ Html.text e.text ] ]
        ]
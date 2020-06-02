module Main exposing (..)

import Browser
import Dict
import Entities exposing (..)
import EntitiesDrawer
import Faction exposing (..)
import Html exposing (Html, button, div, img, span, text)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import ListExt
import Map exposing (Map, MapTile)
import MapData exposing (..)
import MapDrawer
import MapGenerator exposing (createMap)
import MaybeExt
import PathDrawer
import Pathfinder
import Svg exposing (..)
import Svg.Attributes exposing (..)
import Templates.BattleTemplate exposing (..)
import Templates.EndTemplate exposing (..)
import Templates.HeaderTemplate exposing (..)
import Templates.SettlementTemplate exposing (..)
import Troops exposing (Troop, TroopType)
import Types exposing (MapTileMsg(..), Msg(..), SettlementMsg(..), UiSettlementState(..))
import Vector exposing (..)


type alias Model =
    { lords : List Lord
    , gameState : GameState
    , selectedPoint : Maybe Point
    , map : Map.Map --used for pathfinding
    }


type GameState
    = GameSetup UiState
    | InGame Int -- int = playerCount
    | GameOver Bool -- true = gewonnen, false = verloren


type UiState
    = MainMenue
    | SaveLoad
    | NewCampain
    | GameMenue
    | BattleView
    | SettlementView UiSettlementState


hasActionOnPoint : Vector.Point -> MapTileMsg -> MapDrawer.MapClickAction -> Bool
hasActionOnPoint p msg dict =
    List.member msg (List.map .action (actionsOnPoint p dict))


actionsOnPoint : Vector.Point -> MapDrawer.MapClickAction -> List MapDrawer.SvgAction
actionsOnPoint p dict =
    MaybeExt.foldMaybe (\l -> ListExt.justList (List.map .action l)) [] (Dict.get (MapData.hashMapPoint p) dict)


canMoveToPoint : MapDrawer.MapClickAction -> Vector.Point -> Bool
canMoveToPoint dict p =
    hasActionOnPoint p (MoveTo p) dict


getPlayer : Model -> Maybe Entities.Lord
getPlayer m =
    List.head m.lords


buildAllMapSvgs : Model -> MapDrawer.MapClickAction
buildAllMapSvgs m =
    filterMapSvgs
        (buildPathSvgs m
            (List.foldl
                EntitiesDrawer.drawSettlement
                (List.foldl EntitiesDrawer.drawLord (drawnMap m.map) m.lords)
                (allSettlements m)
            )
        )


filterMapSvgs : MapDrawer.MapClickAction -> MapDrawer.MapClickAction
filterMapSvgs =
    Dict.map (\_ v -> filterInteractables v)


filterInteractables : List MapDrawer.InteractableSvg -> List MapDrawer.InteractableSvg
filterInteractables =
    List.foldr
        (\svg r ->
            if MapDrawer.isSvgAllowedIn svg r then
                svg :: r

            else
                r
        )
        []


buildPathSvgs : Model -> MapDrawer.MapClickAction -> MapDrawer.MapClickAction
buildPathSvgs m mapDict =
    case getSelectedPath m of
        Nothing ->
            mapDict

        Just path ->
            case getPlayer m of
                Nothing ->
                    mapDict

                Just player ->
                    PathDrawer.drawPath player.moveSpeed path mapDict


getSelectedPath : Model -> Maybe Pathfinder.Path
getSelectedPath m =
    case getPlayer m of
        Nothing ->
            Nothing

        Just player ->
            case m.selectedPoint of
                Nothing ->
                    Nothing

                Just point ->
                    if canMoveToPoint (drawnMap m.map) point then
                        Pathfinder.getPath
                            player.entity.position
                            (Pathfinder.PathInfo (MapGenerator.getNav m.map) point)

                    else
                        Nothing


allSettlements : Model -> List Settlement
allSettlements m =
    List.concat (List.map .land m.lords)



-- STATIC TEST DATA


testTroopList : List Troop
testTroopList =
    [ { amount = 50, troopType = Troops.Sword }, { amount = 30, troopType = Troops.Spear }, { amount = 30, troopType = Troops.Archer }, { amount = 10, troopType = Troops.Knight } ]


testWorldEntity : WorldEntity
testWorldEntity =
    { army = testTroopList
    , faction = Faction.Faction1
    , position = { x = 0, y = 0 }
    , name = "Malaca"
    }


testSetelement : Settlement
testSetelement =
    { entity = testWorldEntity
    , settlementType = Entities.Village
    , income = 3.19
    , isSieged = False
    }



{- type alias Lord =
   { entity : WorldEntity
   , gold : Gold
   , action : Action
   , land : List Settlement
   , moveSpeed : Float
   }
-}


testLordWorldEntity : WorldEntity
testLordWorldEntity =
    { army = testTroopList
    , faction = Faction.Faction1
    , position = { x = 0, y = 0 }
    , name = "Sir Quicknuss"
    }


testActionType : Action
testActionType =
    { actionType = Wait
    , actionMotive = Flee
    }


testLord : Lord
testLord =
    { entity = testLordWorldEntity
    , gold = 250
    , action = testActionType
    , land = [ testSetelement, testSetelement, testSetelement ]
    , moveSpeed = 1.0
    }



-- STATIC TEST DATA --


initialModel : Model
initialModel =
    let
        map =
            MapGenerator.createMap
    in
    Model [] (GameSetup MainMenue) Nothing map


startGame : Int -> Model
startGame playerCount =
    initPlayers initialModel playerCount


initPlayers : Model -> Int -> Model
initPlayers m count =
    let
        lords =
            List.map
                (\i -> initPlayer i (2 * (toFloat i / toFloat count + 0.125)))
                (List.range 0 (count - 1))
    in
    { m | lords = lords }


drawnMap : Map.Map -> MapDrawer.MapClickAction
drawnMap map =
    Map.drawMap map


initPlayer : Int -> Float -> Lord
initPlayer i rad =
    let
        entity =
            WorldEntity
                []
                (Faction.getFaction i)
                (Vector.toPoint (Vector.pointOnCircle (toFloat MapData.mapSize * 1) rad))
                ("Lord " ++ String.fromInt i)
    in
    Lord
        entity
        0
        (Entities.Action Entities.Wait Entities.Defend)
        (initSettlementsFor entity)
        5


initSettlementsFor : Entities.WorldEntity -> List Entities.Settlement
initSettlementsFor e =
    Entities.createCapitalFor e :: []



--generateSettlementsFor : Lord ->
{-
   addSettlementsTo : Entities.Lord -> List Entities.SettlementInfo -> Model -> Model
   addSettlementsTo l sInfos m =
       let
           mLord =
               List.head (List.filter ((==) l) m.lords)
       in
       case mLord of
           Nothing ->
               m

           Just lord ->
               List.map (Entities.getSettlementFor lord) sInfos


   initField : Map.MapTile -> Map.MapTile
   initField t =
       t

-}


update : Msg -> Model -> Model
update msg model =
    case msg of
        EndRound ->
            model

        EndGame bool ->
            { model | gameState = GameOver bool }

        CloseModal ->
            { model | gameState = GameSetup GameMenue }

        ShowSettlement ->
            { model | gameState = GameSetup (SettlementView StandardView) }

        ShowTroopRecruiting ->
            { model | gameState = GameSetup (SettlementView RecruitView) }

        ShowTroopStationing ->
            { model | gameState = GameSetup (SettlementView StationView) }

        ShowBattleView ->
            { model | gameState = GameSetup BattleView }

        SettlementAction action troopType ->
            updateSettlement action troopType model

        MapTileAction action ->
            model

        Click p ->
            { model | selectedPoint = Just p }


updateSettlement : SettlementMsg -> TroopType -> Model -> Model
updateSettlement msg t model =
    case msg of
        BuyTroops ->
            model

        StationTroops ->
            model

        TakeTroops ->
            model


view : Model -> Html Msg
view model =
    let
        allClickActions =
            buildAllMapSvgs model
    in
    div [ Html.Attributes.class "page-container" ]
        [ findModalWindow model
        , Templates.HeaderTemplate.generateHeaderTemplate testLord
        , div [ Html.Attributes.style "height" "800", Html.Attributes.style "width" "1000px" ]
            [ addStylesheet "link" "./assets/styles/main_styles.css"
            , Svg.svg
                [ Svg.Attributes.viewBox "0 0 2000 1800"
                , Svg.Attributes.width "2000"
                , Svg.Attributes.height "1800"
                , Svg.Attributes.fill "none"
                ]
                (MapDrawer.allSvgs allClickActions)
            ]
        , span [] [ Html.text (gameStateToText model.gameState) ]
        ]



-- temp to test


gameStateToText : GameState -> String
gameStateToText gs =
    case gs of
        GameSetup uistate ->
            case uistate of
                SettlementView _ ->
                    "ja man"

                _ ->
                    "[]"

        _ ->
            "[]"



--temp


findModalWindow : Model -> Html Msg
findModalWindow model =
    case model.gameState of
        GameSetup uistate ->
            case uistate of
                SettlementView sView ->
                    case sView of
                        BuildingView ->
                            div [] []

                        _ ->
                            generateSettlementModalTemplate testLord testSetelement sView

                BattleView ->
                    generateBattleTemplate testLord testLord

                _ ->
                    div [] []

        GameOver bool ->
            generateEndTemplate bool

        _ ->
            div [] []


pointToMsg : Vector.Point -> Msg
pointToMsg p =
    Click p


main : Program () Model Msg
main =
    Browser.sandbox { init = startGame 4, view = view, update = update }


addStylesheet : String -> String -> Html Msg
addStylesheet tag href =
    Html.node tag [ attribute "Rel" "stylesheet", attribute "property" "stylesheet", attribute "href" href ] []

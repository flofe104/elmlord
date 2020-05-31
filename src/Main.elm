module Main exposing (..)

import Browser
import Dict
import Entities exposing (..)
import EntitiesDrawer
import Faction exposing (..)
import Html exposing (Html, button, div, img, span, text)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Map exposing (Map, MapTile)
import MapData exposing (..)
import MapDrawer
import MapGenerator exposing (createMap)
import MaybeExt
import Pathfinder
import Svg exposing (..)
import Svg.Attributes exposing (..)
import Types exposing (MapTileMsg(..), Msg(..))
import Vector exposing (..)
import Troops exposing (..)
import Faction exposing (..)

import Templates.HeaderTemplate exposing (..)
import Templates.SettlementTemplate exposing (..)

type alias Model =
    { lords : List Lord
    , gameState : GameState
    , selectedPoint : Maybe Point
    , map : Map.Map --used for pathfinding
    , mapTileClickActions : MapDrawer.MapClickAction
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
    | SettlementView



--todo : Modell überarbeiten, map generierung anschauen -> pathfinding?
--lordToDrawInfo : Entities.Lord -> MapDrawer.MapDrawInfo Msg MapTileMsg
--lordToDrawInfo l =
-- STATIC TEST DATA


buildAllMapSvgs : Model -> MapDrawer.MapClickAction
buildAllMapSvgs m =
    List.foldl EntitiesDrawer.drawSettlement (List.foldl EntitiesDrawer.drawLord m.mapTileClickActions m.lords) (allSettlements m)


allSettlements : Model -> List Settlement
allSettlements m =
    List.concat (List.map .land m.lords)


testTroopList : List Troop
testTroopList = [{amount = 50, troopType = Troops.Sword}, {amount = 30, troopType = Troops.Spear}, {amount = 30, troopType = Troops.Archer}, {amount = 11, troopType = Troops.Knight}]

testWorldEntity : WorldEntity
testWorldEntity =
    {
        army = testTroopList
        , faction = Faction.Faction1
        , position = {x = 0, y = 0}
        , name = "Malaca"
    }

testSetelement : Settlement
testSetelement =
    {
        entity = testWorldEntity
        , settlementType = Entities.Village
        , income = 3.19
        , isSieged = False
    }

-- STATIC TEST DATA --

initialModel : Model
initialModel =
    let
        map =
            MapGenerator.createMap

        drawnMap =
            Map.drawMap map
    in
    Model [] (GameSetup MainMenue) Nothing map drawnMap


startGame : Int -> Model
startGame playerCount =
    createMapClickActions (initPlayers initialModel playerCount)


initPlayers : Model -> Int -> Model
initPlayers m count =
    let
        lords =
            List.map
                (\i -> initPlayer i (2 * (toFloat i / toFloat count + 0.125)))
                (List.range 0 (count - 1))
    in
    { m | lords = lords }


createMapClickActions : Model -> Model
createMapClickActions m =
    { m | mapTileClickActions = Map.drawMap m.map }


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
        0


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

        CloseModal ->
            { model |  gameState = GameSetup GameMenue}

        ShowSettlement -> 
            { model |  gameState = GameSetup SettlementView}

        Click p ->
            { model | selectedPoint = Just p }


view : Model -> Html Msg
view model =
    let
        allClickActions =
            buildAllMapSvgs model
    in
    div [ Html.Attributes.class "page-container" ]
        [
        findModalWindow model 
        ,Templates.HeaderTemplate.generateHeaderTemplate
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
        , span [] [Html.text (gameStateToText model.gameState)]
        ]

{- type alias Model =
    { lords : List Lord
    , gameState : GameState
    , selectedPoint : Maybe Point
    , map : Map.Map --used for pathfinding
    , mapTileClickActions : MapDrawer.MapClickAction
    }


type GameState
    = GameSetup UiState
    | InGame Int -- int = playerCount
    | GameOver Bool -- true = gewonnen, false = verloren


type UiState
    = MainMenue
    | SaveLoad
    | NewCampain
    | SettlementView -}

-- temp to test
gameStateToText : GameState -> String
gameStateToText gs =
    case gs of
        GameSetup uistate ->
            case uistate of
                SettlementView ->
                    "ja man"
                _ -> 
                    "[]"
        _ ->
            "[]"

--temp
findModalWindow : Model -> Html Msg
findModalWindow  model =
    case model.gameState of
        GameSetup uistate ->
            case uistate of
                SettlementView ->
                    generateSettlementModalTemplate testSetelement
                _ -> 
                    div [] []
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

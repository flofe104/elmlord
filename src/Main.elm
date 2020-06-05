module Main exposing (..)

import Browser
import DateExt
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
import Templates.LordTemplate exposing (..)
import Templates.MapActionTemplate exposing (..)
import Templates.SettlementTemplate exposing (..)
import Troops exposing (Troop, TroopType)
import Types exposing (MapTileMsg(..), Msg(..), SettlementMsg(..), UiSettlementState(..))
import Vector exposing (..)


type alias Model =
    { lords : LordList
    , gameState : GameState
    , selectedPoint : Maybe Point
    , date : DateExt.Date
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
    | SettlementView Lord Settlement UiSettlementState
    | LordView Lord


hasActionOnPoint : Vector.Point -> MapTileMsg -> MapDrawer.MapClickAction -> Bool
hasActionOnPoint p msg dict =
    List.member msg (MapDrawer.actionsOnPoint p dict)


canMoveToPoint : MapDrawer.MapClickAction -> Vector.Point -> Bool
canMoveToPoint dict p =
    hasActionOnPoint p (MoveTo p) dict


buildAllMapSvgs : Model -> MapDrawer.MapClickAction
buildAllMapSvgs m =
    filterMapSvgs
        (buildPathSvgs m
            (List.foldl
                (EntitiesDrawer.drawSettlement testLord)
                (List.foldl (EntitiesDrawer.drawLord testLord) (drawnMap m.map) (Entities.flattenLordList m.lords))
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
    let
        player = Entities.getPlayer m.lords
    in
    case getSelectedPath m of
        Nothing ->
            mapDict

        Just path ->
            PathDrawer.drawPath player.moveSpeed path mapDict


getSelectedPath : Model -> Maybe Pathfinder.Path
getSelectedPath m =
    let
        player = Entities.getPlayer m.lords
    in
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
    List.concat (List.map .land (Entities.flattenLordList m.lords))



-- STATIC TEST DATA


testTroopList : List Troop
testTroopList =
    [ { amount = 30, troopType = Troops.Sword }, { amount = 30, troopType = Troops.Spear }, { amount = 30, troopType = Troops.Archer }, { amount = 30, troopType = Troops.Knight } ]


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
    , settlementType = Entities.Castle
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
    Model (Cons testLord []) (GameSetup MainMenue) Nothing (DateExt.Date 1017 DateExt.Jan) map


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
    { m | lords = (Cons testLord lords) }


drawnMap : Map.Map -> MapDrawer.MapClickAction
drawnMap map =
    Map.drawMap map


initPlayer : Int -> Float -> Lord
initPlayer i rad =
    let
        entity =
            WorldEntity
                testTroopList
                (Faction.getFaction i)
                (Vector.toPoint (Vector.pointOnCircle (toFloat MapData.mapSize * 1) rad))
                ("Lord " ++ String.fromInt i)
    in
    Lord
        entity
        250
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
            { model | date = DateExt.addMonths 1 model.date }

        EndGame bool ->
            { model | gameState = GameOver bool }

        CloseModal ->
            { model | gameState = GameSetup GameMenue }

        ShowBattleView ->
            { model | gameState = GameSetup BattleView }

        SettlementAction action ->
            updateSettlement action model

        MapTileAction action ->
            updateMaptileAction model action

        Click p ->
            { model | selectedPoint = Just p }


updateMaptileAction : Model -> MapTileMsg -> Model
updateMaptileAction model ma =
    case ma of
        LordMsg msg lord ->
            { model | gameState = GameSetup (LordView lord) }

        SettlementMsg msg settlement ->
            { model | gameState = GameSetup (SettlementView (Entities.getPlayer model.lords) settlement Types.StandardView) }

        MoveTo _ ->
            model


updateSettlement : SettlementMsg -> Model -> Model
updateSettlement msg model =
    case msg of
        ShowBuyTroops s ->
            { model | gameState = GameSetup (SettlementView (Entities.getPlayer model.lords) s Types.RecruitView) }

        ShowStationTroops s ->
            { model | gameState = GameSetup (SettlementView (Entities.getPlayer model.lords) s Types.StationView) }

        ShowSettlement s ->
            { model | gameState = GameSetup (SettlementView (Entities.getPlayer model.lords) s Types.StandardView) }

        _ -> 
            updateSettlementWithData msg model

-- very ugly refactore it, just for testing
updateSettlementWithData : SettlementMsg -> Model -> Model
updateSettlementWithData msg model =
    case msg of
        BuyTroops t s l ->
            { model | lords = Entities.updatePlayer model.lords (Entities.buyTroops (Entities.getPlayer model.lords) t), 
                      gameState = GameSetup (SettlementView (Entities.getPlayer model.lords) s Types.RecruitView) }

        StationTroops t s ->
            case Entities.getSettlement (Entities.getPlayer model.lords).land s.entity.name of
                Nothing -> 
                    model

                (Just set) -> 
                    { model | lords = Entities.updatePlayer model.lords (Entities.stationTroops (Entities.getPlayer model.lords) t s), 
                            gameState = GameSetup (SettlementView (Entities.getPlayer model.lords) set Types.StationView) }

        TakeTroops t s->
            case Entities.getSettlement (Entities.getPlayer model.lords).land s.entity.name of
                Nothing -> 
                    model

                (Just set) -> 
                    { model | lords = Entities.updatePlayer model.lords (Entities.takeTroops (Entities.getPlayer model.lords) t s), 
                            gameState = GameSetup (SettlementView (Entities.getPlayer model.lords) set Types.StationView) }

        _ -> 
            model



view : Model -> Html Msg
view model =
    let
        allClickActions =
            buildAllMapSvgs model
    in
    div [ Html.Attributes.class "page-container" ]
        [ findModalWindow model
        , Templates.HeaderTemplate.generateHeaderTemplate (Entities.getPlayer model.lords) model.date
        , div [ Html.Attributes.class "page-map" ]
            [ addStylesheet "link" "./assets/styles/main_styles.css"
            , generateMapActionTemplate model.selectedPoint allClickActions
            , div []
                [ Svg.svg
                    [ Svg.Attributes.viewBox "0 0 850 1000"
                    , Svg.Attributes.fill "none"
                    ]
                    (MapDrawer.allSvgs allClickActions)
                ]
            , span [] [ Html.text (gameStateToText model) ]
            ]
        ]



-- temp to test


gameStateToText : Model -> String
gameStateToText gs =
    String.fromFloat (getPlayer gs.lords).gold



--temp


findModalWindow : Model -> Html Msg
findModalWindow model =
    case model.gameState of
        GameSetup uistate ->
            case uistate of
                SettlementView l s u ->
                    generateSettlementModalTemplate l s u

                LordView l ->
                    generateLordTemplate l

                {- case sView of
                   BuildingView ->
                       div [] []

                   _ ->
                       generateSettlementModalTemplate testLord testSetelement sView
                -}
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


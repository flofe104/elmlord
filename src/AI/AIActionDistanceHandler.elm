module AI.AIActionDistanceHandler exposing (..)

import AI.Model exposing (..)
import Building
import Dict
import Entities
import Entities.Model
import ListExt
import MaybeExt
import PathAgent
import Pathfinder
import Troops
import Vector


distanceFromCapitalSiegeActionPenalty : Int -> Float
distanceFromCapitalSiegeActionPenalty turns =
    toFloat turns * 0.085


distanceFromVillageSiegeActionPenalty : Int -> Float
distanceFromVillageSiegeActionPenalty turns =
    toFloat turns * 0.095


distanceSwapTroopsActionPenalty : Int -> Float
distanceSwapTroopsActionPenalty turns =
    toFloat turns * 0.05


distanceHireTroopsActionPenalty : Int -> Float
distanceHireTroopsActionPenalty turns =
    toFloat turns * 0.045


distanceImproveBuildingActionPenalty : Int -> Float
distanceImproveBuildingActionPenalty turns =
    toFloat turns * 0.09


distanceFromMoveToPenalty : Int -> Float
distanceFromMoveToPenalty turns =
    toFloat turns * 0.075



{-
   For now ai lords are heavily against attacking a lord they cant reach in
   this turn
-}


distanceFromAttackLordPenalty : Int -> Float
distanceFromAttackLordPenalty turns =
    toFloat turns * 2.5


applyActionDistancePenalty : AI -> (Vector.Point -> Int) -> AiRoundActionPreference -> AiRoundActionPreference
applyActionDistancePenalty ai turnsToPoint action =
    let
        destination =
            getAiRoundActionDestination action.action

        turnsToAction =
            MaybeExt.foldMaybe (\p -> turnsToPoint p) 0 destination
    in
    { action
        | actionValue =
            action.actionValue
                - getActionDistancePenalty ai action.action turnsToAction
    }


getActionDistancePenalty : AI -> AiRoundActions -> Int -> Float
getActionDistancePenalty ai a turnsToPoint =
    case a of
        EndRound ->
            0

        GoSomeWhere _ ->
            distanceFromMoveToPenalty turnsToPoint

        DoSomething baseAction ->
            getBaseActionDistancePenalty ai baseAction turnsToPoint


getBaseActionDistancePenalty : AI -> BasicAction -> Int -> Float
getBaseActionDistancePenalty ai basicAction i =
    case basicAction of
        AttackLord l ->
            max 0 <| distanceFromAttackLordPenalty i * (2 - ai.strategy.battleMultiplier)

        HireTroops _ _ ->
            if i < 0 then
                -2

            else
                distanceHireTroopsActionPenalty i * (2 - ai.strategy.defendMultiplier)

        SwapTroops _ s ->
            if i < 0 then
                if s.settlementType == Entities.Model.Castle then
                    min 0 <| 1 - (ai.strategy.defendMultiplier * 3)

                else
                    min 0 <| (1 - (ai.strategy.defendMultiplier + 0.1) * 1.5)

            else
                distanceSwapTroopsActionPenalty i * (2 - ai.strategy.defendMultiplier)

        SiegeSettlement s ->
            if s.settlementType == Entities.Model.Castle then
                distanceFromCapitalSiegeActionPenalty i * (2 - ai.strategy.siegeMultiplier)

            else
                distanceFromVillageSiegeActionPenalty i * (2 - ai.strategy.siegeMultiplier)

        ImproveBuilding _ _ ->
            distanceImproveBuildingActionPenalty <| max 0 i


getAiRoundActionDestination : AiRoundActions -> Maybe Vector.Point
getAiRoundActionDestination a =
    case a of
        EndRound ->
            Nothing

        GoSomeWhere p ->
            Just p

        DoSomething basicAction ->
            Just <| getBasicActionDestination basicAction


getBasicActionDestination : BasicAction -> Vector.Point
getBasicActionDestination basicAction =
    case basicAction of
        AttackLord l ->
            l.entity.position

        HireTroops _ s ->
            s.entity.position

        SwapTroops _ s ->
            s.entity.position

        SiegeSettlement s ->
            s.entity.position

        ImproveBuilding s _ ->
            s.entity.position

module AI.AITroopHandling exposing (..)

import AI.AIGoldManager exposing (..)
import AI.AISettlementHandling
import AI.Model exposing (..)
import Balancing
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


acceptedMissingTroopsStrength : AI -> Int
acceptedMissingTroopsStrength ai =
    round <|
        ((estimatedSettlementDefenseStrength ai Entities.Model.Castle
            + toFloat (estimatedNormalPlayerTroopStrength ai)
            + estimatedSettlementDefenseStrength ai Entities.Model.Village
         )
            / 2
        )


maximalAcceptedSettlementStrength : AI -> Entities.Model.Settlement -> Int
maximalAcceptedSettlementStrength ai s =
    round <| estimatedSettlementDefenseStrength ai s.settlementType * 1.75


maximalAcceptedPlayerStrength : AI -> Int
maximalAcceptedPlayerStrength ai =
    round <| toFloat (estimatedNormalPlayerTroopStrength ai) * 5 + max 500 (ai.lord.gold / 5)


acceptedLackOfDefenseStrength : Int
acceptedLackOfDefenseStrength =
    300


troopStrengthToBotherAddingToSettlement : Int
troopStrengthToBotherAddingToSettlement =
    0


estimatedNormalVillageTroopStrength : AI -> Float
estimatedNormalVillageTroopStrength ai =
    toFloat 2750 * (2 * ai.strategy.defendMultiplier - 1.2)


estimatedNormalCastleTroopStrength : AI -> Float
estimatedNormalCastleTroopStrength ai =
    let
        x =
            toFloat <| Entities.lordSettlementCount ai.lord
    in
    --(400 + (50 * x)) * ai.strategy.defendMultiplier
    (5000 * ((1 / x) + ((1 - (1 / x)) / (x * x * 0.01 + 1)))) * (2 * ai.strategy.defendMultiplier - 1)



--4500 * ai.strategy.defendMultiplier


estimatedNormalPlayerTroopStrength : AI -> Int
estimatedNormalPlayerTroopStrength ai =
    let
        x =
            Entities.lordSettlementCount ai.lord
    in
    (2800 + 400 * x) * round (max ai.strategy.battleMultiplier ai.strategy.siegeMultiplier)


estimatedSettlementDefenseStrength : AI -> Entities.Model.SettlementType -> Float
estimatedSettlementDefenseStrength ai t =
    case t of
        Entities.Model.Village ->
            estimatedNormalVillageTroopStrength ai

        Entities.Model.Castle ->
            estimatedNormalCastleTroopStrength ai


hireTroopsIfNeeded : AI -> List AiRoundActionPreference
hireTroopsIfNeeded ai =
    let
        neededStrength =
            totalNeededTroopStrength ai identity

        recruitTroopsActions =
            checkSettlementsForRecruits (max 1 neededStrength) ai
    in
    if neededStrength > 0 then
        recruitTroopsActions

    else if AI.AIGoldManager.goldIncomePerRound ai > 0 || ai.lord.gold > 1000 then
        List.map (\action -> { action | actionValue = 0.15 }) recruitTroopsActions

    else
        []


settlementDisposableTroops : AI -> Entities.Model.Settlement -> Troops.Army
settlementDisposableTroops ai s =
    takeTroopsToLeaveArmyAtStrength (maximalAcceptedSettlementStrength ai s) s.entity.army


takeTroopsFromSettlements : AI -> List AiRoundActionPreference
takeTroopsFromSettlements ai =
    let
        neededStrength =
            totalNeededTroopStrength ai identity
    in
    ListExt.justList <| List.map (checkSettlementForAvaiableTroops neededStrength ai) ai.lord.land


checkSettlementForAvaiableTroops : Int -> AI -> Entities.Model.Settlement -> Maybe AiRoundActionPreference
checkSettlementForAvaiableTroops targetStrength ai s =
    let
        availableTroops =
            settlementDisposableTroops ai s

        troopStrength =
            Troops.sumArmyStats availableTroops
    in
    if troopStrength > 0 then
        Just <|
            AiRoundActionPreference
                (DoSomething <| SwapTroops (Troops.invertArmy availableTroops) s)
                (min (2 + ai.strategy.defendMultiplier)
                    ((toFloat targetStrength
                        / (toFloat (acceptedMissingTroopsStrength ai) / 3)
                     )
                        * min 1
                            (toFloat troopStrength
                                / toFloat targetStrength
                            )
                    )
                )

    else
        Nothing


checkSettlementsForRecruits : Int -> AI -> List AiRoundActionPreference
checkSettlementsForRecruits targetStrength ai =
    ListExt.justList <|
        List.map
            (checkSettlementForRecruits targetStrength ai)
            ai.lord.land


checkSettlementForRecruits : Int -> AI -> Entities.Model.Settlement -> Maybe AiRoundActionPreference
checkSettlementForRecruits targetStrength ai s =
    let
        recruitNeedFactor =
            min (2 * (2 + ai.strategy.defendMultiplier))
                (toFloat targetStrength / toFloat (acceptedMissingTroopsStrength ai))

        recruitableTroopsDict =
            tryBuyTroopsWithTotalStrenghtFrom ai targetStrength s

        recruitStrengthFactor =
            min 1 <|
                toFloat (Troops.sumArmyStats recruitableTroopsDict)
                    / toFloat targetStrength

        recruitOverflowFactor =
            AI.AISettlementHandling.settlementRecruitUsage ai.lord s s.recruitLimits

        actionValue =
            min (2 + ai.strategy.defendMultiplier) <|
                recruitNeedFactor
                    * (recruitOverflowFactor
                        - AI.AISettlementHandling.settlementRecruitUsage
                            ai.lord
                            s
                            (Troops.substractArmy
                                s.recruitLimits
                                recruitableTroopsDict
                            )
                      )
                    + clamp 0 1 (logBase 10 (recruitStrengthFactor / toFloat acceptedLackOfDefenseStrength))
                    + (1 - ai.strategy.defendMultiplier)
    in
    if recruitStrengthFactor > 0 then
        Just <|
            AiRoundActionPreference
                (DoSomething (HireTroops recruitableTroopsDict s))
                actionValue

    else
        Nothing



--evaluates if any settlements controlled by the current ai have insufficent defense


evaluateSettlementDefense : AI -> Entities.Model.Settlement -> Maybe AiRoundActionPreference
evaluateSettlementDefense ai s =
    if
        settlementLackOfTroopStrength ai s
            - acceptedLackOfDefenseStrength
            < 0
    then
        Nothing

    else if hasTroopsToSatisfySettlementDefense ai then
        let
            swapTroops =
                takeDisposableTroopsWithMaxStrength
                    ai.lord.entity.army
                    (estimatedNormalPlayerTroopStrength ai)
                    (settlementLackOfTroopStrength ai s)
        in
        if Troops.sumArmyStats swapTroops > 0 then
            Just
                (AiRoundActionPreference
                    (DoSomething
                        (SwapTroops swapTroops s)
                    )
                    (min
                        (2 + ai.strategy.defendMultiplier)
                        (toFloat (Troops.sumArmyStats swapTroops)
                            / toFloat (settlementLackOfTroopStrength ai s)
                            + max 0
                                (toFloat (settlementLackOfTroopStrength ai s)
                                    / estimatedSettlementDefenseStrength ai s.settlementType
                                )
                            + (if s.settlementType == Entities.Model.Castle then
                                ai.strategy.defendMultiplier + 0.3

                               else
                                ai.strategy.defendMultiplier * 0.5 + 0.1
                              )
                        )
                    )
                )

        else
            Nothing

    else
        Nothing


settlementLackOfTroopStrength : AI -> Entities.Model.Settlement -> Int
settlementLackOfTroopStrength ai s =
    round (estimatedSettlementDefenseStrength ai s.settlementType)
        - Troops.sumArmyStats s.entity.army


totalNeededTroopStrength : AI -> (Int -> Int) -> Int
totalNeededTroopStrength ai op =
    max 0 <|
        List.foldl
            (\s neededStrength ->
                neededStrength
                    + op
                        (round
                            (toFloat <| maximalAcceptedSettlementStrength ai s)
                            - Troops.sumArmyStats ai.lord.entity.army
                        )
            )
            (max
                0
                (maximalAcceptedPlayerStrength ai
                    - Troops.sumArmyStats ai.lord.entity.army
                )
            )
            ai.lord.land


hasTroopsToSatisfySettlementDefense : AI -> Bool
hasTroopsToSatisfySettlementDefense ai =
    (Troops.sumArmyStats <|
        takeTroopsToLeaveArmyAtStrength
            (estimatedNormalPlayerTroopStrength ai)
            ai.lord.entity.army
    )
        >= troopStrengthToBotherAddingToSettlement


takeDisposableTroopsWithMaxStrength : Troops.Army -> Int -> Int -> Troops.Army
takeDisposableTroopsWithMaxStrength sourceArmy sourceNeededStrength maxStrength =
    takeTroopsToLeaveArmyAtStrength
        (max
            sourceNeededStrength
            (Troops.sumArmyStats sourceArmy - maxStrength)
        )
        sourceArmy


takeTroopsToLeaveArmyAtStrength : Int -> Troops.Army -> Troops.Army
takeTroopsToLeaveArmyAtStrength strength army =
    Tuple.second <|
        Dict.foldl
            (\k v ( currentStrength, dict ) ->
                let
                    troopStats =
                        Troops.troopStrengthDeffSum <| Troops.intToTroopType k

                    notAvailableAmount =
                        clamp 0 v ((strength - currentStrength) // troopStats)
                in
                ( currentStrength + troopStats * notAvailableAmount, Dict.insert k (v - notAvailableAmount) dict )
            )
            ( 0, Dict.empty )
            army


takeTroopsWithStrength : Int -> Troops.Army -> Troops.Army
takeTroopsWithStrength neededStrength army =
    Tuple.second <|
        Dict.foldl
            (\k v ( currentStrength, dict ) ->
                let
                    troopStats =
                        Troops.troopStrengthDeffSum <| Troops.intToTroopType k

                    amount =
                        clamp 0 v ((neededStrength - currentStrength) // troopStats)
                in
                ( currentStrength + troopStats * amount, Dict.insert k amount dict )
            )
            ( 0, Dict.empty )
            army


estimatedTroopStrengthForGold : Int -> Int
estimatedTroopStrengthForGold gold =
    round Troops.averageTroopStrengthCostRatio * gold


troopAmountWithStrength : Int -> Int -> Int
troopAmountWithStrength strength neededStrength =
    max 0 <| round (toFloat neededStrength / toFloat strength)


tryBuyTroopsWithTotalStrenghtFrom : AI -> Int -> Entities.Model.Settlement -> Dict.Dict Int Int
tryBuyTroopsWithTotalStrenghtFrom aI targetStrength settlement =
    Tuple.second <|
        Dict.foldl
            (\k v ( gold, dict ) ->
                let
                    troopCost =
                        Troops.troopCost (Troops.intToTroopType k)

                    amount =
                        AI.AIGoldManager.takeAsMuchAsPossible troopCost
                            gold
                            (min v
                                (troopAmountWithStrength
                                    (Troops.troopStrengthDeffSum <| Troops.intToTroopType k)
                                    (targetStrength - round Troops.averageTroopStrengthCostRatio)
                                )
                            )
                in
                ( gold - toFloat (amount * troopCost), Dict.insert k amount dict )
            )
            ( aI.lord.gold, Dict.empty )
            settlement.recruitLimits

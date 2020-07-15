module Battle exposing (evaluateBattleResult, fleeBattle, siegeBattleAftermath, skipBattle)

import Dict
import Entities
import Map
import OperatorExt
import Troops


battleFleeTroopLoss : Float
battleFleeTroopLoss =
    0.4


{-| Resolves / Calculate a battle skirmish outcome between (lord vs lord or lord vs siege).
Notice that only one round will be calculated!

    @param {BattleStats}: Takes information about the battle (lords, settlement, troops, names, etc.)
    @param {Terrain}: Takes terrain on which the battle takes place on

-}
evaluateBattleResult : Entities.BattleStats -> Map.Terrain -> Entities.BattleStats
evaluateBattleResult bS t =
    if bS.siege then
        case bS.settlement of
            Nothing ->
                bS

            Just settle ->
                evaluateSiegeBattle bS settle t

    else
        evaluateLordBattle bS t


{-| Resolves / Calculate a battle skirmish outcome for sieges

    @param {BattleStats}: Takes information about the battle (lords, settlement, troops, names, etc.)
    @param {Settlement}: Takes the settlement that gets sieged (in BattleStats its a Maybe Settlement)
    @param {Terrain}: Takes terrain on which the battle takes place on

-}
evaluateSiegeBattle : Entities.BattleStats -> Entities.Settlement -> Map.Terrain -> Entities.BattleStats
evaluateSiegeBattle bS settle ter =
    let
        ( transferedDefender, transferedSettle ) =
            siegeBattleSetDefender bS settle

        tempAttacker =
            bS.attacker

        newAttacker =
            { tempAttacker | entity = evaluateBattle tempAttacker.entity transferedSettle.entity.army ter (Entities.getSettlementBonus settle bS.defender.land) }

        newSettle =
            { transferedSettle | entity = evaluateBattle transferedSettle.entity bS.attacker.entity.army ter 1 }

        attackerCasualties =
            calculateEntityCasualties bS.attacker.entity.army newAttacker.entity.army

        defenderCasualties =
            calculateEntityCasualties bS.defender.entity.army newSettle.entity.army
    in
    constructBattleResult bS newAttacker transferedDefender (Just newSettle) attackerCasualties defenderCasualties


{-| Resolves / Calculate a battle skirmish outcome for lord battles

    @param {BattleStats}: Takes information about the battle (lords, settlement, troops, names, etc.)
    @param {Terrain}: Takes terrain on which the battle takes place on

-}
evaluateLordBattle : Entities.BattleStats -> Map.Terrain -> Entities.BattleStats
evaluateLordBattle bS ter =
    let
        tempAttacker =
            bS.attacker

        tempDefender =
            bS.defender

        newAttacker =
            { tempAttacker | entity = evaluateBattle tempAttacker.entity bS.defender.entity.army ter 1 }

        newDefender =
            { tempDefender | entity = evaluateBattle tempDefender.entity bS.attacker.entity.army ter 1 }

        attackerCasualties =
            calculateEntityCasualties bS.attacker.entity.army newAttacker.entity.army

        defenderCasualties =
            calculateEntityCasualties bS.defender.entity.army newDefender.entity.army
    in
    constructBattleResult bS newAttacker newDefender bS.settlement attackerCasualties defenderCasualties


{-| Construct a generic battle result for both sieges and normal battles

    @param {BattleStats}: Takes information about the battle (lords, settlement, troops, names, etc.)
    @param {Lord}: Takes the attacker lord
    @param {Lord}: Takes the defender lord
    @param {Maybe Settlement}: Takes for sieges a settlement therefore only as a maybe data structure
    @param {(List Troop, List Troop)}: Takes the calculated casualties for both sides

-}
constructBattleResult : Entities.BattleStats -> Entities.Lord -> Entities.Lord -> Maybe Entities.Settlement -> Troops.Army -> Troops.Army -> Entities.BattleStats
constructBattleResult bS attacker defender settle aCasu dCasu =
    { bS
        | round = bS.round + 1
        , attackerCasualties = aCasu
        , defenderCasualties = dCasu
        , attacker = lordBattleAftermath attacker
        , defender = lordBattleAftermath defender
        , settlement = settle
        , finished = Troops.sumTroops attacker.entity.army == 0 || checkDefenderArmy defender settle
    }



-- battle aftermath functions
-- like position resets, settlement transfers, etc.
-------------------------------------------------------------------------------------


{-| Check if the player lost the normal battle, if thats the case his position gets a reset to his
capital position

    @param {Lord}: Takes the attacker-/defender lord

-}
lordBattleAftermath : Entities.Lord -> Entities.Lord
lordBattleAftermath lord =
    if Troops.sumTroops lord.entity.army == 0 then
        case Entities.getLordCapital lord.land of
            Nothing ->
                lord

            Just settle ->
                { lord | entity = Entities.setPosition lord.entity settle.entity.position }

    else
        lord


siegeBattleAftermath : Entities.BattleStats -> Entities.Settlement -> ( Entities.Lord, Entities.Lord, Bool )
siegeBattleAftermath bS s =
    let
        attacker =
            bS.attacker

        defender =
            bS.defender
    in
    if Troops.sumTroops s.entity.army <= 0 then
        if s.settlementType == Entities.Castle then
            handleSettlementTransfer attacker defender (\y -> y.settlementType /= Entities.Castle) []

        else
            handleSettlementTransfer attacker defender (\y -> y.entity.name == s.entity.name) (List.filter (\y -> y.entity.name /= s.entity.name) defender.land)

    else
        ( attacker, defender, False )


fleeBattle : Entities.BattleStats -> Entities.Lord
fleeBattle bS =
    Entities.updatePlayerArmy bS.attacker (Dict.map (\k v -> round (toFloat v * (1 - battleFleeTroopLoss))) bS.attacker.entity.army)


skipBattle : Entities.BattleStats -> Map.Terrain -> Entities.BattleStats
skipBattle bS ter =
    let
        newBattleStats =
            evaluateBattleResult bS ter
    in
    if newBattleStats.finished then
        newBattleStats

    else
        skipBattle newBattleStats ter



-- helper functions for the construction of the battle result
-------------------------------------------------------------------------------------


siegeBattleSetDefender : Entities.BattleStats -> Entities.Settlement -> ( Entities.Lord, Entities.Settlement )
siegeBattleSetDefender bS settle =
    if Entities.isLordOnSettlement bS.defender settle then
        transferTroops bS.defender settle

    else
        ( bS.defender, settle )


checkDefenderArmy : Entities.Lord -> Maybe Entities.Settlement -> Bool
checkDefenderArmy defender settle =
    case settle of
        Nothing ->
            Troops.sumTroops defender.entity.army == 0

        Just s ->
            Troops.sumTroops s.entity.army == 0


handleSettlementTransfer : Entities.Lord -> Entities.Lord -> (Entities.Settlement -> Bool) -> List Entities.Settlement -> ( Entities.Lord, Entities.Lord, Bool )
handleSettlementTransfer attacker defender aFunc ndl =
    ( { attacker
        | land =
            List.map (\x -> { x | entity = Entities.updateEntityFaction attacker.entity.faction x.entity })
                (List.filter aFunc defender.land)
                ++ attacker.land
      }
    , { defender | land = ndl }
    , List.length ndl == 0
    )


{-| Transfers the troops of a lord to the besieged settlement (only if the player stands on this settlement)

    @param {Lord}: Takes the defender lord
    @param {Maybe Settlement}: Takes the sieged settlement
    @param {( Entities.Lord, Entities.Settlement )}: Returns the entities with the transfered armies

-}
transferTroops : Entities.Lord -> Entities.Settlement -> ( Entities.Lord, Entities.Settlement )
transferTroops l s =
    let
        newArmy =
            Troops.mergeTroops l.entity.army s.entity.army

        newLord =
            { l | entity = Entities.updateEntitiesArmy Dict.empty l.entity }

        newSettlement =
            { s | entity = Entities.updateEntitiesArmy newArmy s.entity }
    in
    ( newLord, newSettlement )



-- battle evaluation and helper functions
-------------------------------------------------------------------------------------


evaluateBattle : Entities.WorldEntity -> Troops.Army -> Map.Terrain -> Float -> Entities.WorldEntity
evaluateBattle w army ter siegeBonus =
    evaluateLordCasualities w (sumTroopsDamage army ter siegeBonus)


calculateEntityCasualties : Troops.Army -> Troops.Army -> Troops.Army
calculateEntityCasualties armyBefore armyAfter =
    Dict.merge
        (\k v r -> Dict.insert k 0 r)
        (\k v1 v2 r -> Dict.insert k (v2 - v1) r)
        (\k v2 r -> Dict.insert k 0 r)
        armyBefore
        armyAfter
        Dict.empty


evaluateLordCasualities : Entities.WorldEntity -> Float -> Entities.WorldEntity
evaluateLordCasualities w d =
    { w | army = calcTroopCasualties w.army d (Troops.sumTroops w.army) }


calcTroopCasualties : Troops.Army -> Float -> Int -> Troops.Army
calcTroopCasualties army d a =
    Dict.map (\k v -> calcCasualties (Troops.intToTroopType k) v ((d + 100.0) * (toFloat v / toFloat a))) army


calcCasualties : Troops.TroopType -> Int -> Float -> Int
calcCasualties t amount d =
    max 0 (amount - round (d / Troops.troopDefense t))


sumTroopsDamage : Troops.Army -> Map.Terrain -> Float -> Float
sumTroopsDamage army ter siegeBonus =
    let
        bonusTroopTypes =
            Map.terrainToBonus ter
    in
    Dict.foldl
        (\k v dmg ->
            dmg
                + siegeBonus
                * OperatorExt.ternary
                    (List.member (Troops.intToTroopType k) bonusTroopTypes)
                    (Troops.battlefieldBonus (Troops.intToTroopType k))
                    1
                * Troops.troopDamage (Troops.intToTroopType k)
                * toFloat v
        )
        0
        army

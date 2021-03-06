module Troops exposing (..)

import Dict
import MaybeExt


type alias Army =
    Dict.Dict Int Int


type TroopType
    = Archer
    | Spear
    | Sword
    | Knight



-- base entity (lords, settlements, etc.) armies
----------------------------------------------------------


lordStartTroops : Army
lordStartTroops =
    List.foldl (\( t, v ) dict -> Dict.insert (troopTypeToInt t) v dict)
        Dict.empty
        [ ( Archer, 5 ), ( Spear, 15 ), ( Sword, 10 ), ( Knight, 5 ) ]


capitalStartTroops : Army
capitalStartTroops =
    List.foldl (\( t, v ) dict -> Dict.insert (troopTypeToInt t) v dict)
        Dict.empty
        [ ( Archer, 30 ), ( Spear, 5 ), ( Sword, 15 ), ( Knight, 5 ) ]


villageStartTroops : Army
villageStartTroops =
    List.foldl (\( t, v ) dict -> Dict.insert (troopTypeToInt t) v dict)
        Dict.empty
        [ ( Archer, 15 ), ( Spear, 0 ), ( Sword, 15 ), ( Knight, 0 ) ]



-- General troop functions
-- merge, update, etc. armies
----------------------------------------------------------


mergeTroops : Army -> Army -> Army
mergeTroops a1 a2 =
    Dict.merge Dict.insert (\k v1 v2 r -> Dict.insert k (v1 + v2) r) Dict.insert a1 a2 Dict.empty


troopTypeList : List TroopType
troopTypeList =
    [ Knight, Archer, Spear, Sword ]


troopKeyList : List Int
troopKeyList =
    List.map troopTypeToInt troopTypeList


updateTroops : Army -> TroopType -> Int -> Army
updateTroops army t i =
    Dict.update (troopTypeToInt t) (\v -> Just (Maybe.withDefault 0 v + i)) army


updateTroopsFrom : Army -> Int -> Int -> Army
updateTroopsFrom army i =
    updateTroops army <| intToTroopType i


emptyTroops : Army
emptyTroops =
    List.foldl (\t dict -> Dict.insert (troopTypeToInt t) 0 dict) Dict.empty troopTypeList


substractArmy : Army -> Army -> Army
substractArmy a1 a2 =
    Dict.foldl (\k v army -> updateTroopsFrom army k -v) a1 a2


sumTroops : Army -> Int
sumTroops a =
    List.foldl (+) 0 (Dict.values a)


getTroopTypeInArmyStats : Army -> TroopType -> Int
getTroopTypeInArmyStats a t =
    MaybeExt.foldMaybe (sumTroopStats t) 0 <| Dict.get (troopTypeToInt t) a


sumArmyStats : Army -> Int
sumArmyStats =
    Dict.foldl (\k v r -> sumTroopStats (intToTroopType k) v + r) 0


sumTroopStats : TroopType -> Int -> Int
sumTroopStats t amount =
    round (troopDamage t + troopDefense t) * amount


invertArmy : Army -> Army
invertArmy =
    Dict.map (\_ v -> -v)


averageTroopStrengthCostRatio : Float
averageTroopStrengthCostRatio =
    Tuple.first <|
        List.foldl
            (\t ( r, c ) ->
                ( r
                    + (toFloat (troopStrengthDeffSum t)
                        / toFloat (troopCost t)
                        - r
                      )
                    / c
                , c + 1
                )
            )
            ( 0, 1 )
            troopTypeList



-- Resolve a troop type to different values like
-- wages, costs, fighting-stats, etc.
----------------------------------------------------------


troopStrengthDeffSum : TroopType -> Int
troopStrengthDeffSum t =
    round (troopDamage t + troopDefense t)


troopCost : TroopType -> Int
troopCost t =
    case t of
        Archer ->
            35

        Spear ->
            15

        Sword ->
            40

        Knight ->
            50


troopWage : TroopType -> Float
troopWage t =
    case t of
        Archer ->
            0.1

        Spear ->
            0.3

        Sword ->
            0.25

        Knight ->
            0.5


troopDamage : TroopType -> Float
troopDamage t =
    case t of
        Archer ->
            8

        Spear ->
            9

        Sword ->
            8

        Knight ->
            12


troopDefense : TroopType -> Float
troopDefense t =
    case t of
        Archer ->
            35

        Spear ->
            35

        Sword ->
            65

        Knight ->
            90


troopName : TroopType -> String
troopName t =
    case t of
        Archer ->
            "Archer"

        Spear ->
            "Spear"

        Sword ->
            "Sword"

        Knight ->
            "Knight"


battlefieldBonus : TroopType -> Float
battlefieldBonus t =
    case t of
        Archer ->
            1.2

        Spear ->
            1.1

        Sword ->
            1.075

        Knight ->
            1.05


troopTypeToInt : TroopType -> Int
troopTypeToInt t =
    case t of
        Sword ->
            0

        Spear ->
            1

        Archer ->
            2

        Knight ->
            3


intToTroopType : Int -> TroopType
intToTroopType i =
    case i of
        0 ->
            Sword

        1 ->
            Spear

        2 ->
            Archer

        3 ->
            Knight

        _ ->
            Spear

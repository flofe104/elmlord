module Entities.Lords exposing (..)

import AI
import Entities.Model exposing (..)
import List


type LordList
    = Cons Lord (List AI.AI)


lordListToList : LordList -> List Lord
lordListToList (Cons l ais) =
    l :: List.map .lord ais


npcs : LordList -> List Lord
npcs (Cons _ ais) =
    List.map .lord ais


getAis : LordList -> List AI.AI
getAis (Cons _ ais) =
    ais


replaceAi : LordList -> AI.AI -> LordList
replaceAi lordList newAi =
    Cons (getPlayer lordList)
        (List.map
            (\ai ->
                if ai.lord.entity.name == newAi.lord.entity.name then
                    newAi

                else
                    ai
            )
            (getAis lordList)
        )


getLordsExcept : LordList -> Lord -> List Lord
getLordsExcept ls lord =
    List.foldr
        (\l r ->
            if l.entity.name == lord.entity.name then
                r

            else
                l :: r
        )
        []
        (lordListToList ls)


updatePlayer : LordList -> Lord -> LordList
updatePlayer (Cons _ ps) np =
    Cons np ps


getPlayer : LordList -> Lord
getPlayer (Cons p _) =
    p
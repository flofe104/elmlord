module Entities.Lords exposing (..)

import AI.Model
import Entities.Model exposing (..)
import List


type LordList
    = Cons Lord (List AI.Model.AI)


lordListToList : LordList -> List Lord
lordListToList (Cons l ais) =
    l :: List.map .lord ais


getAiWithName : LordList -> String -> Maybe AI.Model.AI
getAiWithName (Cons l ais) name =
    List.head <| List.filter (\ai -> ai.lord.entity.name == name) ais


updateNpcs : LordList -> List AI.Model.AI -> LordList
updateNpcs (Cons l _) ais =
    Cons l ais


npcs : LordList -> List Lord
npcs (Cons _ ais) =
    List.map .lord ais


getAis : LordList -> List AI.Model.AI
getAis (Cons _ ais) =
    ais


getLordIndex : LordList -> Lord -> Int
getLordIndex ls toCheck =
    List.foldl
        (\l index ->
            if toCheck.entity.name == l.entity.name then
                index

            else
                index + 1
        )
        0
        (lordListToList ls)



{-
   isLordsTurnBeforeLord : LordList -> Lord -> Lord -> Bool
   isLordsTurnBeforeLord ls toCheck beforeThis =
       Maybe.withDefault True <|
           List.foldl
               (\l isBefore ->
                   case isBefore of
                       Nothing ->
                           if toCheck.entity.name == l.entity.name then
                               Just True

                           else if beforeThis.entity.name == l.entity.name then
                               Just False

                           else
                               Nothing
               )
               Nothing
               (npcs ls)
-}


replaceAi : LordList -> AI.Model.AI -> LordList
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


updateLord : Entities.Model.Lord -> LordList -> LordList
updateLord l (Cons player ais) =
    if player.entity.name == l.entity.name then
        Cons l ais

    else
        Cons player
            (List.map
                (\ai ->
                    if ai.lord.entity.name == l.entity.name then
                        { ai | lord = l }

                    else
                        ai
                )
                ais
            )


removeLord : LordList -> Lord -> Maybe LordList
removeLord (Cons player ais) l =
    if player.entity.name == l.entity.name then
        Nothing

    else
        Just <|
            Cons player
                (List.filter
                    (\ai ->
                        ai.lord.entity.name /= l.entity.name
                    )
                    ais
                )


updatePlayer : LordList -> Lord -> LordList
updatePlayer (Cons _ ps) np =
    Cons np ps


getPlayer : LordList -> Lord
getPlayer (Cons p _) =
    p

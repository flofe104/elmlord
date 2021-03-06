module ListExt exposing (getElementAt, indexOf, insertToSortedList, justList, removeElementAt)

import MaybeExt


indexOf : (a -> Bool) -> List a -> Int
indexOf p xs =
    indexOf_ 0 p xs


justList : List (Maybe a) -> List a
justList =
    List.foldr (\m r -> MaybeExt.foldMaybe (\a -> a :: r) r m) []


getElementAt : Int -> List a -> Maybe a
getElementAt i l =
    if i <= 0 then
        List.head l

    else
        Maybe.andThen (getElementAt (i - 1)) (List.tail l)


removeElementAt : Int -> List a -> List a
removeElementAt i l =
    Tuple.first <|
        List.foldr
            (\a ( r, index ) ->
                if index == i then
                    ( r, index + 1 )

                else
                    ( a :: r, index + 1 )
            )
            ( [], 0 )
            l


indexOf_ : Int -> (a -> Bool) -> List a -> Int
indexOf_ i p xs =
    case xs of
        [] ->
            -1

        x :: xs2 ->
            if p x then
                i

            else
                indexOf_ (i + 1) p xs2


insertToSortedList : a -> (a -> comparable) -> List a -> List a
insertToSortedList a f xs =
    case xs of
        [] ->
            [ a ]

        x :: xs2 ->
            if f a <= f x then
                a :: x :: xs2

            else
                x :: insertToSortedList a f xs2

module Example.FourPrime where

import Prelude
import Data.Either
import Data.Functor.Coproduct
import Data.Array (filter)
import Control.Plus (Plus)

import Halogen
import qualified Halogen.HTML.Indexed as H
import qualified Halogen.HTML.Events.Indexed as E

import qualified Example.CounterRemPrime as Counter
import qualified Example.RemGeneric as Rem
import Example.Two (CounterSlot(..))
import Example.Three (StateP(), addCounter, initialState)

data Input a = AddCounter a

type State g =
  InstalledState StateP (Counter.State g) Input Counter.Query g CounterSlot

type Query =
  Coproduct Input (ChildF CounterSlot Counter.Query)

ui :: forall g. (Plus g)
   => Component (State g) Query g
ui = parentComponent' render eval peek
  where
    render state =
      H.div_ 
        [ H.h1_ [ H.text "Counters" ]
        , H.ul_ (map mkChild state.counterArray)
        , H.button [ E.onClick $ E.input_ AddCounter ]
                   [ H.text "Add Counter" ]
        ]

    mkChild i = H.slot (CounterSlot i) \_ -> { component: Counter.ui, initialState: installedState unit }

    eval :: EvalParent Input StateP _ Input _ g CounterSlot
    eval (AddCounter next) = do
      modify addCounter
      pure next

    peek :: Peek (ChildF CounterSlot Counter.Query) StateP (Counter.State g) Input Counter.Query g CounterSlot
    peek (ChildF counterSlot (Coproduct queryAction)) =
      case queryAction of
           Left (Rem.Remove _) ->
             modify (removeCounter counterSlot)
           _ ->
             pure unit

removeCounter :: CounterSlot -> StateP -> StateP
removeCounter (CounterSlot index) state =
    state { counterArray = filter (/= index) state.counterArray }

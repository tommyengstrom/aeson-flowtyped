{-# LANGUAGE DeriveGeneric     #-}
{-# LANGUAGE OverloadedStrings #-}
import           Data.Aeson            (Value)
import           Data.Aeson.Flow
import           Data.Functor.Foldable (Fix (..))
import           Data.Proxy            (Proxy (..))
import           Data.Text             (Text)
import           Data.Vector           (Vector)
import           GHC.Generics
import           Test.Tasty
import           Test.Tasty.HUnit

data User = User
  { username  :: Text
  , realname  :: Maybe Text
  , dob       :: Maybe (Int, Int, Int)
  , extraInfo :: Value
  } deriving (Generic)

instance FlowTyped User

data Recur = Recur
  { asdf   :: Int
  , stuff  :: [User]
  , recurs :: [Recur]
  } deriving (Generic)

instance FlowTyped Recur

data Adt2 = A2 | B2 deriving (Generic)
instance FlowTyped Adt2

data Adt3 = A3 | B3 | C3 deriving (Generic)
instance FlowTyped Adt3

data Adt4 = A4 | B4 | C4 | D4 deriving (Generic)
instance FlowTyped Adt4

data Codep = Codep
  { corecurs :: [Recur]
  , cousers  :: [User]
  } deriving (Generic)

instance FlowTyped Codep

main :: IO ()
main = defaultMain $ testGroup "aeson-flowtyped"
  [ testCase "nullable" $
     showFlowType (flowType (Proxy :: Proxy (Maybe Int))) @=?
     showFlowType (Fix (Nullable (Fix (Prim Number))))

  , testCase "array" $ do
     showFlowType (flowType (Proxy :: Proxy [Int])) @=?
       showFlowType (Fix (Array (Fix (Prim Number))))

     showFlowType (flowType (Proxy :: Proxy (Vector Int))) @=?
       showFlowType (Fix (Array (Fix (Prim Number))))

    -- XXX: actually use Eq

  , testCase "User export" $
    "export type User =\n\
    \  {| extraInfo: mixed,\n\
    \     tag: 'User',\n\
    \     realname: ?string,\n\
    \     username: string,\n\
    \     dob: ?[number,number,number] |};" @=?
    exportFlowTypeAs "User" (flowType (Proxy :: Proxy User))

  , testCase "Recursive type export" $
    "export type Recur =\n\
    \  {| tag: 'Recur', stuff: User[], recurs: Recur[], asdf: number |};" @=?
    exportFlowTypeAs "Recur" (flowType (Proxy :: Proxy Recur))

  , testCase "Nullary string tags (2 tags)" $
    "export type Adt2 =\n\
    \  'A2' |\n\
    \  'B2';" @=?
    exportFlowTypeAs "Adt2" (flowType (Proxy :: Proxy Adt2))

  , testCase "Nullary string tags (3 tags)" $
    "export type Adt3 =\n\
    \  'A3' |\n\
    \  'B3' |\n\
    \  'C3';" @=?
    exportFlowTypeAs "Adt3" (flowType (Proxy :: Proxy Adt3))

  , testCase "Nullary string tags (4 tags)" $
    "export type Adt4 =\n\
    \  'A4' |\n\
    \  'B4' |\n\
    \  'C4' |\n\
    \  'D4';" @=?
    exportFlowTypeAs "Adt4" (flowType (Proxy :: Proxy Adt4))

  , testCase "module export" $
    "// @flow\n\
    \// This module has been generated by aeson-flowtyped.\n\n\
    \export type Codep =\n\
    \  {| corecurs: Recur[], tag: 'Codep', cousers: User[] |};\n\
    \export type User =\n\
    \  {| extraInfo: mixed,\n\
    \     tag: 'User',\n\
    \     realname: ?string,\n\
    \     username: string,\n\
    \     dob: ?[number,number,number] |};\n\
    \export type Recur =\n\
    \  {| tag: 'Recur', stuff: User[], recurs: Recur[], asdf: number |};\n" @=?
    generateFlowModule defaultFlowModuleOptions
    [ Export (Proxy :: Proxy Codep)
    ]

  ]

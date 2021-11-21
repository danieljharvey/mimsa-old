{-# LANGUAGE DataKinds #-}
{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DerivingStrategies #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TypeOperators #-}

module Language.Mimsa.Server.Project.BindType
  ( bindType,
    BindType,
  )
where

import qualified Data.Aeson as JSON
import Data.OpenApi
import Data.Text (Text)
import GHC.Generics
import qualified Language.Mimsa.Actions.BindType as Actions
import qualified Language.Mimsa.Actions.Helpers.Parse as Actions
import qualified Language.Mimsa.Actions.Helpers.Swaps as Actions
import Language.Mimsa.Codegen
import Language.Mimsa.Printer
import Language.Mimsa.Server.Handlers
import Language.Mimsa.Server.Helpers.ExpressionData
import Language.Mimsa.Server.MimsaHandler
import Language.Mimsa.Server.Types
import Language.Mimsa.Types.AST
import Language.Mimsa.Types.Identifiers
import Language.Mimsa.Types.Project
import Language.Mimsa.Types.ResolvedExpression
import Language.Mimsa.Types.Store
import Servant

------

type BindType =
  "type"
    :> ReqBody '[JSON] BindTypeRequest
    :> JsonPost BindTypeResponse

data BindTypeRequest = BindTypeRequest
  { btProjectHash :: ProjectHash,
    btExpression :: Text
  }
  deriving stock (Eq, Ord, Show, Generic)
  deriving anyclass (JSON.FromJSON, ToSchema)

data CodegenInfo = CodegenInfo {ciExprName :: Name, ciHash :: ExprHash}
  deriving stock (Eq, Ord, Show, Generic)
  deriving anyclass (JSON.ToJSON, ToSchema)

data BindTypeResponse = BindTypeResponse
  { btProjectData :: ProjectData,
    btDataType :: DataType,
    btPrettyType :: Text,
    btCodegen :: Maybe ExpressionData,
    btTypeclasses :: [Typeclass]
  }
  deriving stock (Eq, Ord, Show, Generic)
  deriving anyclass (JSON.ToJSON, ToSchema)

bindType ::
  MimsaEnvironment ->
  BindTypeRequest ->
  MimsaHandler BindTypeResponse
bindType mimsaEnv (BindTypeRequest projectHash input) = runMimsaHandlerT $ do
  let action = do
        expr <- Actions.parseDataType input
        (typeClasses, codegenInfo, dt, gv) <- Actions.bindType input expr
        ed <- case codegenInfo of
          Just resolvedExpr -> do
            let se = reStoreExpression resolvedExpr
            typedNameExpr <-
              Actions.useSwaps
                (reSwaps resolvedExpr)
                (reTypedExpression resolvedExpr)
            ed' <- expressionData se typedNameExpr gv input
            pure (Just ed')
          Nothing -> pure Nothing
        pure (ed, typeClasses, dt)
  response <-
    lift $ eitherFromActionM mimsaEnv projectHash action
  case response of
    Right (newProject, (ed, typeClasses, dt)) -> do
      pd <- lift $ projectDataHandler mimsaEnv newProject
      returnMimsa $
        BindTypeResponse pd dt (prettyPrint dt) ed typeClasses
    Left e -> throwMimsaError e

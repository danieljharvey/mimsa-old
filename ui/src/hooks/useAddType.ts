import * as React from 'react'
import { bindType } from '../service/project'
import {
  initial,
  pending,
  RemoteData,
  failure,
  success,
} from '@devexperts/remote-data-ts'
import {
  BindTypeResponse,
  Typeclass,
  ProjectData,
  UserErrorResponse,
} from '../generated'
import { pipe } from 'fp-ts/function'
import * as E from 'fp-ts/Either'
import { ExprHash } from '../types/'

// this is how we should do the screens from now on

type AddType = {
  bindings: Record<string, string>
  typeBindings: Record<string, string>
  typeclasses: Typeclass[]
  dataTypePretty: string
}

type State = RemoteData<UserErrorResponse, AddType>

export const useAddType = (
  projectHash: string,
  code: string,
  updateProject: (
    pd: ProjectData,
    hashes: ExprHash[]
  ) => void
) => {
  const [typeState, setTypeState] =
    React.useState<State>(initial)

  const addNewType = async () => {
    setTypeState(pending)
    const result = await bindType({
      btProjectHash: projectHash,
      btExpression: code,
    })()

    pipe(
      result,
      E.fold<UserErrorResponse, BindTypeResponse, State>(
        (e) => failure(e),
        (a) => {
          updateProject(
            a.btProjectData,
            Object.values(a.btCodegen?.edBindings || {})
          )
          return success({
            bindings: a.btCodegen?.edBindings || {},
            typeBindings: a.btCodegen?.edTypeBindings || {},
            typeclasses: a.btTypeclasses,
            dataTypePretty: a.btPrettyType,
          })
        }
      ),
      setTypeState
    )
  }
  return [addNewType, typeState] as const
}

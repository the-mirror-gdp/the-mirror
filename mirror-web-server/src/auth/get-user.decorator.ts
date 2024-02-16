import { createParamDecorator, ExecutionContext } from '@nestjs/common'

/**
 * @description request full UserTokenData or pick specific properties
 *  via passing in the string of the key
 */
export const UserToken = createParamDecorator(
  (data: string, ctx: ExecutionContext) => {
    const request = ctx.switchToHttp().getRequest()
    const userToken: UserTokenData = request.user

    return data ? userToken?.[data] : userToken
  }
)

export const UserBearerToken = createParamDecorator(
  (data: string, ctx: ExecutionContext) => {
    const req = ctx.switchToHttp().getRequest()
    const token: string = req.headers?.authorization
    return token.replace('Bearer ', '')
  }
)

export interface UserTokenData {
  name: string
  iss: string
  aud: string
  auth_time: number
  user_id: string
  sub: string
  iat: number
  exp: number
  email: string
  email_verified: boolean
  firebase: UserTokenDataFirebase
  uid: string
}

export interface UserTokenDataFirebase {
  identities: UserTokenDataIdentities
  sign_in_provider: string
}

interface UserTokenDataIdentities {
  email: string[]
}

import { createParamDecorator, ExecutionContext } from '@nestjs/common'
import { UserTokenData } from '../auth/get-user.decorator'

export const UserTokenWS = createParamDecorator(
  (data: string, ctx: ExecutionContext) => {
    // get client information  from the request WS object
    const request = ctx.switchToWs().getClient()

    // get user decode token object from the request object
    const userToken: UserTokenData = request?.user
    return data ? userToken?.[data] : userToken
  }
)

export const AdminTokenWS = createParamDecorator(
  (data: string, ctx: ExecutionContext) => {
    // get client information  from the request WS object
    const request = ctx.switchToWs().getClient()

    // get role from the request object
    const userRole = request?.role

    // check if the user has the admin role
    return userRole === 'admin' ? true : false
  }
)

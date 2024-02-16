import { NODE_ENV } from './../util/node-env.enum'
import { FirebaseAuthenticationService } from '../firebase/firebase-authentication.service'
import {
  applyDecorators,
  CanActivate,
  ExecutionContext,
  Injectable,
  Logger,
  MethodNotAllowedException,
  UseGuards
} from '@nestjs/common'
import { Reflector } from '@nestjs/core'
import { ApiBearerAuth } from '@nestjs/swagger'
import { Request } from 'express'
import { IS_PUBLIC_KEY } from './public.decorator'

@Injectable()
export class AuthGuardFirebase implements CanActivate {
  constructor(
    private readonly firebaseAuthService: FirebaseAuthenticationService,
    private readonly reflector: Reflector,
    private readonly logger: Logger
  ) {}

  public async canActivate(context: ExecutionContext): Promise<boolean> {
    /** If Public decorator is used, bypass auth token requirement */
    const isPublic = this.reflector.getAllAndOverride<boolean>(IS_PUBLIC_KEY, [
      context.getHandler(),
      context.getClass()
    ])

    const req: Request = context.switchToHttp().getRequest()
    const token = req.headers?.authorization

    if (isPublic) {
      // even though public, still decode the jwt if it's there
      /** On Valid token response, assign to the Request.user making it accessible in @UserToken() */
      try {
        const decodedJwt = await this.decodeJwt(token)
        if (decodedJwt) {
          // TODO type this
          req['user'] = decodedJwt
        }
      } catch (error) {
        console.log(error)
        // do nothing if decoding fails here
      }
      return true
    }

    // if not public and no token, reject
    if (!token) {
      this.logger.log(
        'Token is falsey, returning false',
        AuthGuardFirebase.name
      )
      return false
    }

    // not public and token exists, so decode
    try {
      const decodedJwt = await this.decodeJwt(token)
      /** On Valid token response, assign to the Request.user making it accessible in @UserToken() */
      // TODO type this
      req['user'] = decodedJwt
      return true
    } catch (error) {
      /** On Invalid token response, log error and reject request */
      this.logger.error('Error decoding JWT', error)

      // safety in case the WSS token is there (shouldn't occur, but we shouldn't log it)
      if (token.length < 300) {
        this.logger.error(
          'JWT length was ' +
            token.length +
            '. Check to see if it is actually a JWT. URL: ' +
            req.url
        )
        // only log it if we're not in prod for security reasons
        if (process.env.NODE_ENV !== NODE_ENV.PRODUCTION) {
          let logToken = token
          if (logToken === process.env.WSS_SECRET) {
            logToken = '<reacted WSS_SECRET>'
          }
          this.logger.error('JWT: ' + logToken)
        }
        throw new MethodNotAllowedException('Invalid JWT')
      } else {
        this.logger.error('JWT:', token)
      }
      console.log('AuthGuardFirebase: error decoding jwt, returning false')
      return false
    }
  }

  async decodeJwt(token) {
    return await this.firebaseAuthService.verifyIdToken(
      token.replace('Bearer ', ''),
      true
    )
  }
}

export function FirebaseTokenAuthGuard() {
  return applyDecorators(UseGuards(AuthGuardFirebase), ApiBearerAuth())
}

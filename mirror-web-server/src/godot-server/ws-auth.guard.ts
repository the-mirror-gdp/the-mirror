import { CanActivate, ExecutionContext, Injectable } from '@nestjs/common'

import { Socket } from 'socket.io'
import { FirebaseAuthenticationService } from '../firebase/firebase-authentication.service'
import { WsAuthHelperService } from './ws-auth-helper.service'

/**
 * @description This is used with WsAuthHelperService to ensure that the user is authed before processing a request
 * See: https://github.com/nestjs/nest/issues/882#issuecomment-1493106283
 */
@Injectable()
export class WsAuthGuard implements CanActivate {
  constructor(private readonly wsAuthHelperService: WsAuthHelperService) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const client = context.switchToWs().getClient<Socket>()

    // wait until client data initialization will be finished
    const check =
      (await this.wsAuthHelperService.finishInitialization(
        client['id'] as any
      )) ||
      this.wsAuthHelperService.initializationSuccess[client['id'] as string]
    return check
  }
}

import { LoggerModule } from '../util/logger/logger.module'

import { Module } from '@nestjs/common'
import { WsAuthGuard } from './ws-auth.guard'
import { WsAuthHelperService } from './ws-auth-helper.service'
import { GodotGateway } from './godot.gateway'
import { FirebaseModule } from '../firebase/firebase.module'

@Module({
  imports: [LoggerModule, FirebaseModule],
  providers: [GodotGateway, WsAuthHelperService, WsAuthGuard],
  exports: [WsAuthGuard, WsAuthHelperService]
})
export class GodotModule {}

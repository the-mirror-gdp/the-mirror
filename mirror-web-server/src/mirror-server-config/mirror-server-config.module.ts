import { Module } from '@nestjs/common'
import { MongooseModule } from '@nestjs/mongoose'
import {
  MirrorServerConfig,
  MirrorServerConfigSchema
} from './mirror-server-config.schema'
import { MirrorServerConfigService } from './mirror-server-config.service'
import { MirrorServerConfigController } from './mirror-server-config.controller'
import { LoggerModule } from '../util/logger/logger.module'

@Module({
  imports: [
    LoggerModule,
    MongooseModule.forFeature([
      { name: MirrorServerConfig.name, schema: MirrorServerConfigSchema }
    ])
  ],
  controllers: [MirrorServerConfigController],
  providers: [MirrorServerConfigService],
  exports: [MirrorServerConfigService]
})
export class MirrorServerConfigModule {}

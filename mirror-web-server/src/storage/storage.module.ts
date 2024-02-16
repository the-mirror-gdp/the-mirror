import { Module } from '@nestjs/common'
import { MirrorServerConfigModule } from '../mirror-server-config/mirror-server-config.module'
import { LoggerModule } from '../util/logger/logger.module'
import { StorageController } from './storage.controller'
import { StorageService } from './storage.service'

@Module({
  imports: [LoggerModule, MirrorServerConfigModule],
  providers: [StorageService],
  controllers: [StorageController]
})
export class StorageModule {}

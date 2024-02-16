import { Logger, Module } from '@nestjs/common'
import { SpaceModule } from '../space/space.module'
import { CronService } from './cron.service'
import { LoggerModule } from '../util/logger/logger.module'

@Module({
  imports: [SpaceModule, LoggerModule],
  providers: [CronService, Logger],
  exports: [CronService]
})
export class CronModule {}

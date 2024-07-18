import { Logger, Module } from '@nestjs/common'
import { SpaceModule } from '../space/space.module'
import { CronService } from './cron.service'
import { LoggerModule } from '../util/logger/logger.module'
import { MongooseModule } from '@nestjs/mongoose'
import { User, UserSchema } from '../user/user.schema'
import { MixpanelModule } from '../mixpanel/mixpanel.module'

@Module({
  imports: [
    SpaceModule,
    LoggerModule,
    MixpanelModule,
    MongooseModule.forFeature([{ name: User.name, schema: UserSchema }])
  ],
  providers: [CronService, Logger],
  exports: [CronService]
})
export class CronModule {}

import { Injectable, Logger } from '@nestjs/common'
import { SpaceService } from '../space/space.service'
import { Cron, CronExpression } from '@nestjs/schedule'
import { InjectModel } from '@nestjs/mongoose'
import { Model } from 'mongoose'
import { User, UserDocument } from '../user/user.schema'
import { MixpanelService } from '../mixpanel/mixpanel.service'

@Injectable()
export class CronService {
  constructor(
    private readonly spaceService: SpaceService,
    private readonly logger: Logger,
    private readonly mixpanelService: MixpanelService,
    @InjectModel(User.name) private userModel: Model<UserDocument>
  ) {}

  @Cron(CronExpression.EVERY_30_SECONDS)
  async updateSpacesUserActionsStatsAndUsersPresents() {
    try {
      await this.spaceService.updateSpacesUserActionsStatsAndUserPresents()

      this.logger.log(
        'Update Spaces User Actions Stats And Users Presents success',
        CronService.name
      )
    } catch (err) {
      this.logger.error(
        'Update Spaces User Actions Stats And Users Presents failed',
        err.stack,
        CronService.name
      )
    }
  }
}

import { Injectable, Logger } from '@nestjs/common'
import { SpaceService } from '../space/space.service'
import { Cron, CronExpression } from '@nestjs/schedule'

@Injectable()
export class CronService {
  constructor(
    private readonly spaceService: SpaceService,
    private readonly logger: Logger
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

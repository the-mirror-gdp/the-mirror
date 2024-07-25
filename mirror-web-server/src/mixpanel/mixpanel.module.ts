import { Module } from '@nestjs/common'
import { MixpanelService } from './mixpanel.service'

@Module({
  imports: [],
  providers: [MixpanelService],
  exports: [MixpanelService]
})
export class MixpanelModule {}

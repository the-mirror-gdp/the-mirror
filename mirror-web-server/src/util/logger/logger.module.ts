import { Logger, Module } from '@nestjs/common'

@Module({
  providers: [Logger],
  exports: [Logger]
})
export class LoggerModule {}

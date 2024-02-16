import { LoggerModule } from './../util/logger/logger.module'
import { Global, Module } from '@nestjs/common'
import { RedisPubSubService } from './redis-pub-sub.service'

@Global()
@Module({
  imports: [LoggerModule],
  providers: [RedisPubSubService],
  exports: [RedisPubSubService]
})
export class RedisModule {}

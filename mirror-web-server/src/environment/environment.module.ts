import { LoggerModule } from './../util/logger/logger.module'
import { Module } from '@nestjs/common'
import { EnvironmentController } from './environment.controller'
import { EnvironmentService } from './environment.service'
import { MongooseModule } from '@nestjs/mongoose'
import { Environment, EnvironmentSchema } from './environment.schema'
import { EnvironmentGateway } from './environment.gateway'

@Module({
  imports: [
    LoggerModule,
    MongooseModule.forFeature([
      { name: Environment.name, schema: EnvironmentSchema }
    ])
  ],
  controllers: [EnvironmentController],
  providers: [EnvironmentService, EnvironmentGateway],
  exports: [EnvironmentService]
})
export class EnvironmentModule {}

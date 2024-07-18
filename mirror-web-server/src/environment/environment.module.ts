import { LoggerModule } from './../util/logger/logger.module'
import { Module, forwardRef } from '@nestjs/common'
import { EnvironmentController } from './environment.controller'
import { EnvironmentService } from './environment.service'
import { MongooseModule } from '@nestjs/mongoose'
import { Environment, EnvironmentSchema } from './environment.schema'
import { EnvironmentGateway } from './environment.gateway'
import { Space, SpaceSchema } from '../space/space.schema'
import { SpaceModule } from '../space/space.module'
import { GodotModule } from '../godot-server/godot.module'

@Module({
  imports: [
    LoggerModule,
    GodotModule,
    MongooseModule.forFeature([
      { name: Environment.name, schema: EnvironmentSchema }
    ]),
    MongooseModule.forFeature([{ name: Space.name, schema: SpaceSchema }]),
    forwardRef(() => SpaceModule)
  ],
  controllers: [EnvironmentController],
  providers: [EnvironmentService, EnvironmentGateway],
  exports: [EnvironmentService]
})
export class EnvironmentModule {}

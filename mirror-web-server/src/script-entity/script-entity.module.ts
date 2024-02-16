import { LoggerModule } from './../util/logger/logger.module'
import { Module } from '@nestjs/common'
import { MongooseModule } from '@nestjs/mongoose'
import { ScriptEntityController } from './script-entity.controller'
import { ScriptEntityGateway } from './script-entity.gateway'
import { ScriptEntity, ScriptEntitySchema } from './script-entity.schema'
import { ScriptEntityService } from './script-entity.service'
import { UserModule } from '../user/user.module'

@Module({
  imports: [
    LoggerModule,
    MongooseModule.forFeature([
      { name: ScriptEntity.name, schema: ScriptEntitySchema }
    ]),
    UserModule
  ],
  controllers: [ScriptEntityController],
  providers: [ScriptEntityService, ScriptEntityGateway],
  exports: [ScriptEntityService]
})
export class ScriptEntityModule {}

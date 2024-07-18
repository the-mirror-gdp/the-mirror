import { LoggerModule } from './../util/logger/logger.module'
import { Module } from '@nestjs/common'
import { MongooseModule } from '@nestjs/mongoose'
import { ScriptEntityController } from './script-entity.controller'
import { ScriptEntityGateway } from './script-entity.gateway'
import { ScriptEntity, ScriptEntitySchema } from './script-entity.schema'
import { ScriptEntityService } from './script-entity.service'
import { UserModule } from '../user/user.module'
import { RoleModule } from '../roles/role.module'
import { GodotModule } from '../godot-server/godot.module'

@Module({
  imports: [
    LoggerModule,
    GodotModule,
    MongooseModule.forFeature([
      { name: ScriptEntity.name, schema: ScriptEntitySchema }
    ]),
    UserModule,
    RoleModule
  ],
  controllers: [ScriptEntityController],
  providers: [ScriptEntityService, ScriptEntityGateway],
  exports: [ScriptEntityService]
})
export class ScriptEntityModule {}

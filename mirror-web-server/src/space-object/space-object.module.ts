import { RoleModule } from './../roles/role.module'
import { SpaceModule } from './../space/space.module'
import { forwardRef, Module } from '@nestjs/common'
import { MongooseModule } from '@nestjs/mongoose'
import { SpaceObjectService } from './space-object.service'
import { SpaceObjectGateway } from './space-object.gateway'
import { SpaceObjectController } from './space-object.controller'
import { SpaceObject, SpaceObjectSchema } from './space-object.schema'
import { PaginationService } from '../util/pagination/pagination.service'
import { LoggerModule } from '../util/logger/logger.module'
import { AssetModule } from '../asset/asset.module'
import { SpaceObjectSearch } from './space-object.search'
import { ScriptEntityModule } from '../script-entity/script-entity.module'
import { GodotModule } from '../godot-server/godot.module'

@Module({
  imports: [
    LoggerModule,
    RoleModule,
    ScriptEntityModule,
    GodotModule,
    forwardRef(() => SpaceModule), // to fix circular dependency
    MongooseModule.forFeature([
      { name: SpaceObject.name, schema: SpaceObjectSchema }
    ]),
    forwardRef(() => AssetModule)
  ],
  controllers: [SpaceObjectController],
  providers: [
    SpaceObjectService,
    SpaceObjectGateway,
    PaginationService,
    SpaceObjectSearch
  ],
  exports: [SpaceObjectService]
})
export class SpaceObjectModule {}

import { forwardRef, Module } from '@nestjs/common'
import { SpaceSearch } from './space.search'
import { SpaceService } from './space.service'
import { SpaceGateway } from './space.gateway'
import { MongooseModule } from '@nestjs/mongoose'
import { Space, SpaceSchema } from './space.schema'
import { SpaceController } from './space.controller'
import { TerrainModule } from '../terrain/terrain.module'
import { FileUploadModule } from '../util/file-upload/file-upload.module'
import { SpaceObjectModule } from '../space-object/space-object.module'
import { EnvironmentModule } from '../environment/environment.module'
import { FileUploadService } from '../util/file-upload/file-upload.service'
import { AssetModule } from '../asset/asset.module'
import { AssetService } from '../asset/asset.service'
import { Asset, AssetSchema } from '../asset/asset.schema'
import { AssetSearch } from '../asset/asset.search'
import { PaginationService } from '../util/pagination/pagination.service'
import { Material, MaterialSchema } from '../asset/material.schema'
import { Texture, TextureSchema } from '../asset/texture.schema'

import { SpaceVersion, SpaceVersionSchema } from './space-version.schema'
import { UserGroupModule } from '../user-groups/user-group.module'
import { RoleModule } from '../roles/role.module'
import { SpaceGodotServerController } from './space-godot-server.controller'
import { CustomDataModule } from '../custom-data/custom-data.module'
import { LoggerModule } from '../util/logger/logger.module'
import {
  SpaceObject,
  SpaceObjectSchema
} from '../space-object/space-object.schema'
import { SpaceVariablesDataModule } from '../space-variable/space-variables-data.module'
import { MapAsset, MapSchema } from '../asset/map.schema'
import {
  PurchaseOption,
  PurchaseOptionSchema
} from '../marketplace/purchase-option.subdocument.schema'
import { MirrorServerConfigModule } from '../mirror-server-config/mirror-server-config.module'
import { MaterialInstanceController } from './material-instance/material-instance.controller'
import { MaterialInstanceGateway } from './material-instance/material-instance.gateway'
import { MaterialInstanceService } from './material-instance/material-instance.service'
import { ZoneModule } from '../zone/zone.module'
import { UserModule } from '../user/user.module'
import { RedisModule } from '../redis/redis.module'
import { MirrorDBModule } from '../mirror-db/mirror-db.module'
import { ScriptEntityModule } from '../script-entity/script-entity.module'
import { AuthGuardFirebase } from '../auth/auth.guard'
import { StorageModule } from '../storage/storage.module'
import { GodotModule } from '../godot-server/godot.module'

@Module({
  imports: [
    LoggerModule,
    ScriptEntityModule,
    GodotModule,
    MongooseModule.forFeature([
      { name: PurchaseOption.name, schema: PurchaseOptionSchema }
    ]),
    MongooseModule.forFeature([{ name: Space.name, schema: SpaceSchema }]),
    MongooseModule.forFeature([
      { name: SpaceVersion.name, schema: SpaceVersionSchema }
    ]),
    MongooseModule.forFeature([
      {
        name: Asset.name,
        schema: AssetSchema,
        discriminators: [
          {
            name: Material.name,
            schema: MaterialSchema
          },
          {
            name: Texture.name,
            schema: TextureSchema
          },
          {
            name: MapAsset.name,
            schema: MapSchema
          }
        ]
      }
    ]),
    MongooseModule.forFeature([
      { name: SpaceObject.name, schema: SpaceObjectSchema }
    ]),
    CustomDataModule,
    SpaceVariablesDataModule,
    FileUploadModule,
    forwardRef(() => SpaceObjectModule), // to fix circular dependency
    AssetModule,
    TerrainModule,
    EnvironmentModule,
    UserGroupModule,
    RoleModule,
    MirrorServerConfigModule,
    UserModule,
    forwardRef(() => ZoneModule),
    RedisModule,
    MirrorDBModule,
    StorageModule
  ],
  controllers: [
    SpaceController,
    SpaceGodotServerController,
    MaterialInstanceController
  ],
  providers: [
    SpaceService,
    SpaceSearch,
    SpaceGateway,
    FileUploadService,
    AssetService,
    AssetSearch,
    PaginationService,
    MaterialInstanceService,
    MaterialInstanceGateway,
    AuthGuardFirebase
  ],
  exports: [SpaceService]
})
export class SpaceModule {}

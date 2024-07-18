import { PaginationModule } from './../util/pagination/pagination.module'
import { Module, forwardRef } from '@nestjs/common'
import { HttpModule } from '@nestjs/axios'
import { ZoneService } from './zone.service'
import { ZoneGateway } from './zone.gateway'
import { Zone, ZoneSchema } from './zone.schema'
import { MongooseModule } from '@nestjs/mongoose'
import { ZoneController } from './zone.controller'
import { SpaceSearch } from '../space/space.search'
import { AssetSearch } from '../asset/asset.search'
import { SpaceService } from '../space/space.service'
import { AssetService } from '../asset/asset.service'
import { TerrainModule } from '../terrain/terrain.module'
import { SpaceManagerExternalService } from './space-manager-external.service'
import { Space, SpaceSchema } from '../space/space.schema'
import { Asset, AssetSchema } from '../asset/asset.schema'
import { EnvironmentModule } from '../environment/environment.module'
import { SpaceObjectModule } from '../space-object/space-object.module'
import { FileUploadModule } from '../util/file-upload/file-upload.module'
import { PaginationService } from '../util/pagination/pagination.service'
import { Material, MaterialSchema } from '../asset/material.schema'
import { Texture, TextureSchema } from '../asset/texture.schema'

import { SpaceVersion, SpaceVersionSchema } from '../space/space-version.schema'
import { GodotServerOverrideConfigModule } from '../godot-server-override-config/godot-server-override-config.module'
import { UserGroupModule } from '../user-groups/user-group.module'
import { RoleModule } from '../roles/role.module'
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
import {
  UserEntityAction,
  UserEntityActionSchema
} from '../user/models/user-entity-action.schema'
import { SpaceModule } from '../space/space.module'
import { UserModule } from '../user/user.module'
import { StorageModule } from '../storage/storage.module'
import { GodotModule } from '../godot-server/godot.module'

@Module({
  imports: [
    LoggerModule,
    HttpModule,
    GodotServerOverrideConfigModule,
    PaginationModule,
    MongooseModule.forFeature([
      { name: PurchaseOption.name, schema: PurchaseOptionSchema }
    ]),
    MongooseModule.forFeature([{ name: Space.name, schema: SpaceSchema }]),
    MongooseModule.forFeature([{ name: Zone.name, schema: ZoneSchema }]),
    MongooseModule.forFeature([
      { name: SpaceVersion.name, schema: SpaceVersionSchema }
    ]),
    MongooseModule.forFeature([
      { name: UserEntityAction.name, schema: UserEntityActionSchema }
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
    forwardRef(() => SpaceObjectModule),
    TerrainModule,
    EnvironmentModule,
    UserGroupModule,
    RoleModule,
    MirrorServerConfigModule,
    forwardRef(() => SpaceModule),
    UserModule,
    StorageModule,
    GodotModule
  ],
  controllers: [ZoneController],
  providers: [
    ZoneService,
    SpaceManagerExternalService,
    SpaceSearch,
    ZoneGateway,
    AssetService,
    AssetSearch,
    PaginationService
  ],

  exports: [ZoneService, SpaceManagerExternalService]
})
export class ZoneModule {}

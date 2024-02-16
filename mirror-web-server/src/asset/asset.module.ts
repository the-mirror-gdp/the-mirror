import { SpaceObjectModule } from './../space-object/space-object.module'
import { LoggerModule } from './../util/logger/logger.module'
import { forwardRef, Module } from '@nestjs/common'
import { AssetService } from './asset.service'
import { AssetController } from './asset.controller'
import { Asset, AssetSchema } from './asset.schema'
import { MongooseModule } from '@nestjs/mongoose'
import { FileUploadModule } from '../util/file-upload/file-upload.module'
import { AssetSearch } from './asset.search'
import { PaginationService } from '../util/pagination/pagination.service'
import { AssetGateway } from './asset.gateway'
import { Material, MaterialSchema } from './material.schema'
import { Texture, TextureSchema } from './texture.schema'
import { MapAsset, MapSchema } from './map.schema'
import {
  SpaceObject,
  SpaceObjectSchema
} from '../space-object/space-object.schema'
import { RoleModule } from '../roles/role.module'
import {
  PurchaseOption,
  PurchaseOptionSchema
} from '../marketplace/purchase-option.subdocument.schema'
import { UserModule } from '../user/user.module'
import { AuthGuardFirebase } from '../auth/auth.guard'

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: PurchaseOption.name, schema: PurchaseOptionSchema }
    ]),
    LoggerModule,
    RoleModule,
    forwardRef(() => SpaceObjectModule), // to fix circular dependency
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
    forwardRef(() => UserModule),
    forwardRef(() => FileUploadModule) // to fix circular dependency
  ],
  controllers: [AssetController],
  providers: [
    AssetService,
    AssetSearch,
    PaginationService,
    AssetGateway,
    PurchaseOption,
    AuthGuardFirebase
  ],
  exports: [AssetService]
})
export class AssetModule {}

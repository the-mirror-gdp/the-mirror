import * as mongoose from 'mongoose'
import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose'
import { Document } from 'mongoose'
import { User, UserPublicData } from '../user/user.schema'
import { ASSET_TYPE } from '../option-sets/asset-type'
import { ApiProperty } from '@nestjs/swagger'
import { Vector4AsArray } from '../option-sets/vectors'
import { CustomData } from '../custom-data/models/custom-data.schema'
import {
  PurchaseOption,
  PurchaseOptionSchema
} from '../marketplace/purchase-option.subdocument.schema'
import {
  LicenseSchema,
  License
} from '../marketplace/license.subdocument.schema'
import { Role, RoleSchema } from '../roles/models/role.schema'
import { Tags, TagsSchema } from '../tag/models/tags.schema'

export type AssetDiscriminators = 'MapAsset' | 'Material' | 'Texture'

// Properties must not be undefined so that getPublicPropertiesForMongooseQuery can work
export class AssetPublicData {
  @ApiProperty() // @ApiProperty must be included to be exposed by the API and flow to FE codegen
  _id = '' // Must not be undefined
  @ApiProperty()
  createdAt = new Date()
  @ApiProperty()
  updatedAt = new Date()
  @ApiProperty()
  name = ''
  @ApiProperty({
    enum: ASSET_TYPE
  })
  assetType = ASSET_TYPE.IMAGE
  @ApiProperty()
  description = ''
  @ApiProperty()
  mirrorPublicLibrary = false

  /**
   * @deprecated Use .role property instead
   * @date 2023-05-05 09:25
   */
  @ApiProperty({
    type: UserPublicData,
    description: 'Deprecated: use .role property instead'
  })
  owner = new UserPublicData()

  @ApiProperty({
    type: [PurchaseOption],
    required: false,
    description:
      'Array of PurchaseOptions, e.g. for sale at xyz price with abc license. Each purchaseOption has an enabled boolean'
  })
  purchaseOptions = []

  @ApiProperty({
    type: UserPublicData
  })
  creator = new UserPublicData()
  @ApiProperty()
  public = true
  @ApiProperty()
  thumbnail = ''
  @ApiProperty({ type: Tags })
  tags = {}
  // Transform properties.
  @ApiProperty()
  initPositionX = 0
  @ApiProperty()
  initPositionZ = 0
  @ApiProperty()
  initRotationX = 0
  @ApiProperty()
  initRotationY = 0
  @ApiProperty()
  initRotationZ = 0
  @ApiProperty()
  initScaleX = 0
  @ApiProperty()
  initScaleY = 0
  @ApiProperty()
  initScaleZ = 0
  // Physics properties.
  @ApiProperty()
  collisionEnabled = true
  @ApiProperty()
  staticEnabled = true
  @ApiProperty()
  massKg = 1.0
  @ApiProperty()
  gravityScale = 1.0
  // Material properties.
  @ApiProperty()
  objectColor = [1.0, 1.0, 1.0, 1.0]
  @ApiProperty()
  isSoftDeleted: boolean
  @ApiProperty()
  softDeletedAt: string
}

export type AssetDocument = Asset & Document // Note: we also have subclasses/disciminators for materials and textures (as of 2023-02-04 20:18:08). Walkthrough: https://www.loom.com/share/7e09d2777ef94368bcd5fd8c8341b5ef

@Schema({
  timestamps: true,
  toJSON: {
    virtuals: true
  }
})
export class Asset {
  @ApiProperty()
  _id: string

  @ApiProperty()
  createdAt: Date // this is managed by mongoose timestamps: true, but defining it here so types will align
  @ApiProperty()
  updatedAt: Date // this is managed by mongoose timestamps: true, but defining it here so types will align

  @Prop({
    required: true
  })
  @ApiProperty()
  name: string

  @Prop({
    required: true,
    default: () => ASSET_TYPE.PANEL,
    enum: ASSET_TYPE,
    type: String
  })
  @ApiProperty({ enum: ASSET_TYPE })
  assetType: string

  @Prop({
    required: false,
    default: () => ASSET_TYPE.PANEL,
    enum: ASSET_TYPE,
    type: String
  })
  @ApiProperty({ enum: ASSET_TYPE })
  gameplayType: string

  @Prop()
  @ApiProperty()
  description: string

  @Prop({
    required: true,
    default: false
  })
  @ApiProperty()
  mirrorPublicLibrary: boolean // also see thirdPartySource tag

  @Prop({ type: mongoose.Schema.Types.ObjectId, ref: 'CustomData' })
  @ApiProperty()
  customData: CustomData

  /**
   * @deprecated Use .role property instead
   * @date 2023-05-05 09:25
   */
  @Prop({ type: mongoose.Schema.Types.ObjectId, ref: 'User', required: false })
  @ApiProperty({
    description: 'Deprecated: use .role property instead'
  })
  owner: User

  @Prop({ type: [PurchaseOptionSchema], required: false })
  @ApiProperty({
    type: () => PurchaseOption,
    description:
      'Array of PurchaseOptions, e.g. for sale at xyz price with abc license. Each purchaseOption has an enabled boolean'
  })
  purchaseOptions?: PurchaseOption[]

  @Prop({ type: LicenseSchema, required: false })
  @ApiProperty({
    type: () => License,
    description: 'License for the entity. By default, a creator has all rights.'
  })
  license?: License

  @Prop({ type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true })
  @ApiProperty()
  creator: User

  /**
   * @deprecated Use .role property instead
   * @date 2023-05-05 09:25
   */
  @Prop({
    required: true,
    default: true
  })
  @ApiProperty({
    description: 'Deprecated: use .role property instead'
  })
  public: boolean // should the asset be viewable by public?

  @Prop(String)
  @ApiProperty()
  thumbnail: string

  @Prop()
  @ApiProperty()
  currentFile: string

  // Transform properties.
  @Prop({})
  @ApiProperty()
  initPositionX: number

  @Prop({})
  @ApiProperty()
  initPositionY: number

  @Prop({})
  @ApiProperty()
  initPositionZ: number

  @Prop({
    default: 0
  })
  @ApiProperty()
  initRotationX: number

  @Prop({
    default: 0
  })
  @ApiProperty()
  initRotationY: number

  @Prop({
    default: 0
  })
  @ApiProperty()
  initRotationZ: number

  @Prop({
    default: 0
  })
  @ApiProperty()
  initScaleX: number

  @Prop({
    default: 0
  })
  @ApiProperty()
  initScaleY: number

  @Prop({
    default: 0
  })
  @ApiProperty()
  initScaleZ: number

  // Physics properties.
  @Prop({
    default: true
  })
  @ApiProperty()
  collisionEnabled: boolean

  @Prop({
    default: true
  })
  @ApiProperty()
  staticEnabled: boolean

  @Prop({
    default: 1.0
  })
  @ApiProperty()
  massKg: number

  @Prop({
    default: 1.0
  })
  @ApiProperty()
  gravityScale: number

  @Prop({ type: TagsSchema, required: false, default: {} })
  @ApiProperty()
  tags: Tags

  @Prop({ type: Boolean, required: false })
  @ApiProperty()
  isSoftDeleted: boolean

  @Prop({ type: Date, required: false })
  @ApiProperty()
  softDeletedAt: string

  @Prop({ type: Boolean, required: false })
  @ApiProperty()
  isEquipable: boolean

  // Material properties.
  @Prop({
    default: [1.0, 1.0, 1.0, 1.0],
    type: mongoose.Types.Array
  })
  @ApiProperty()
  objectColor: Vector4AsArray

  /**
   * START Section: ISchemaWithRole implementer
   */
  @Prop({
    required: true,
    type: RoleSchema
  })
  @ApiProperty()
  role: Role
  /**
   * END Section: ISchemaWithRole implementer
   */
}

export const AssetSchema = SchemaFactory.createForClass(Asset)

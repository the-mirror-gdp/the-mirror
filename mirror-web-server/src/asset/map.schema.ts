import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose'
import { ApiProperty } from '@nestjs/swagger'
import * as mongoose from 'mongoose'
import { Document } from 'mongoose'
import { Role, RoleSchema } from '../roles/models/role.schema'
import { ISchemaWithRole } from '../roles/role-consumer.interface'
import { AssetPublicData } from './asset.schema'
import { Material } from './material.schema'
import { Asset } from '../asset/asset.schema'
import { Vector4AsArray } from '../option-sets/vectors'

// Properties must not be undefined so that getPublicPropertiesForMongooseQuery can work
export class MapPublicData extends AssetPublicData {
  @ApiProperty({
    example: 'Concrete_super_shiny_example'
  })
  mapName = ''
  @ApiProperty()
  heightmapAssetId = ''
  @ApiProperty()
  flatMaterialAssetId = ''
  @ApiProperty()
  cliffMaterialAssetId = ''
  @ApiProperty()
  mapSize = 512
  @ApiProperty()
  mapPrecision = 1.0
  @ApiProperty()
  heightScale = 32.0
  @ApiProperty()
  layerOffset = 0.0
  @ApiProperty()
  flatUVScale = 1.0
  @ApiProperty()
  cliffUVScale = 1.0
  @ApiProperty()
  flatCliffRatio = -0.6
  @ApiProperty()
  flatColor = [1.0, 1.0, 1.0, 1.0]
  @ApiProperty()
  cliffColor = [1.0, 1.0, 1.0, 1.0]
  @ApiProperty()
  colormapAssetId = ''
  @ApiProperty()
  colormapStrength = 1.0
}

export type MapDocument = MapAsset & Document

@Schema({
  timestamps: true,
  toJSON: {
    virtuals: true
  }
  // discriminatorKey: __t <- don't uncomment this line: this line is to note that __t is the Mongoose default discriminator key that we use for simplicity rather than specifying our own discriminator key. When this schema is instantiated, __t is "MapAsset". This is DIFFERENT from assetType since we hadn't been using discriminators up until 2023-02-04 18:49:52. See https://mongoosejs.com/docs/discriminators.html#discriminator-keys. Walkthrough: https://www.loom.com/share/7e09d2777ef94368bcd5fd8c8341b5ef
})
export class MapAsset {
  _id: string
  @Prop({
    trim: true,
    required: true
  })
  @ApiProperty({
    example: 'Mountain_hill_example'
  })
  mapName: string

  /**
   * Optional properties
   */
  @Prop({
    required: false,
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Asset'
  })
  @ApiProperty()
  heightmapAssetId?: Asset

  @Prop({
    required: false,
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Material'
  })
  @ApiProperty()
  flatMaterialAssetId?: Material

  @Prop({
    required: false,
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Material'
  })
  @ApiProperty()
  cliffMaterialAssetId?: Material

  @Prop({
    required: false,
    default: 512.0,
    type: Number
  })
  @ApiProperty()
  mapSize?: number

  @Prop({
    required: false,
    default: 1.0,
    type: Number
  })
  @ApiProperty()
  mapPrecision?: number

  @Prop({
    required: false,
    default: 32.0,
    type: Number
  })
  @ApiProperty()
  heightScale?: number

  @Prop({
    required: false,
    default: 32.0,
    type: Number
  })
  @ApiProperty()
  layerOffset?: number

  @Prop({
    required: false,
    default: 1.0,
    type: Number
  })
  @ApiProperty()
  flatUVScale?: number

  @Prop({
    required: false,
    default: 1.0,
    type: Number
  })
  @ApiProperty()
  cliffUVScale?: number

  @Prop({
    required: false,
    default: -0.6
  })
  @ApiProperty()
  flatCliffRatio?: number

  @Prop({
    required: false,
    type: mongoose.Types.Array,
    default: [1.0, 1.0, 1.0, 1.0]
  })
  @ApiProperty()
  flatColor?: Vector4AsArray

  @Prop({
    required: false,
    type: mongoose.Types.Array,
    default: [1.0, 1.0, 1.0, 1.0]
  })
  @ApiProperty()
  cliffColor?: Vector4AsArray

  @Prop({
    required: false,
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Material'
  })
  @ApiProperty()
  colormapAssetId?: mongoose.Schema.Types.ObjectId

  @Prop({
    required: false,
    default: 0.5,
    type: Number
  })
  @ApiProperty()
  colormapStrength?: number

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

export const MapSchema = SchemaFactory.createForClass(MapAsset)

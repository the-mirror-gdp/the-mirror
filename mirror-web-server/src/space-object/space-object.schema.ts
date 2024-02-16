import * as mongoose from 'mongoose'
import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose'
import { Document } from 'mongoose'
import { Space } from '../space/space.schema'
import { Asset } from '../asset/asset.schema'
import { ApiProperty } from '@nestjs/swagger'
import { Vector3AsArray, Vector4AsArray } from '../option-sets/vectors'
import { CustomData } from '../custom-data/models/custom-data.schema'
import { User } from '../user/user.schema'
import { Role, RoleSchema } from '../roles/models/role.schema'
import { TagsSchema, Tags } from '../tag/models/tags.schema'

export class SpaceObjectPublicData {
  @ApiProperty({ type: 'string' })
  name = ''

  @ApiProperty({ type: 'string' })
  description = ''

  @ApiProperty({
    anyOf: [
      {
        $ref: '#/components/schemas/User' // There may be a better way to do this? But this DOES work for FE codegen.
      }
      // { type: 'string' }
    ]
  })
  creator: User

  @ApiProperty({
    anyOf: [
      {
        $ref: '#/components/schemas/Asset' // There may be a better way to do this? But this DOES work for FE codegen.
      }
      // { type: 'string' }
    ]
  })
  asset: Asset

  @ApiProperty({
    anyOf: [
      {
        $ref: '#/components/schemas/CustomData' // There may be a better way to do this? But this DOES work for FE codegen.
      }
      // { type: 'string' }
    ]
  })
  customData: CustomData

  @ApiProperty({ type: 'string' })
  role: Role

  @ApiProperty({ type: 'string' })
  parentSpaceObject?: mongoose.Schema.Types.ObjectId

  @ApiProperty({ type: 'boolean' })
  isGroup?: boolean

  @ApiProperty({ type: 'string' })
  parentId?: string

  @ApiProperty({
    anyOf: [
      {
        $ref: '#/components/schemas/Space' // There may be a better way to do this? But this DOES work for FE codegen.
      }
      // { type: 'string' }
    ]
  })
  space: Space

  @ApiProperty({ type: 'boolean' })
  locked: boolean

  @ApiProperty({ type: 'boolean' })
  preloadBeforeSpaceStarts?: boolean

  @ApiProperty({ type: Array })
  position: Vector3AsArray

  @ApiProperty({ type: Array })
  rotation: Vector3AsArray

  @ApiProperty({ type: Array })
  scale: Vector3AsArray

  @ApiProperty({ type: Array })
  offset: Vector3AsArray

  @ApiProperty({ type: 'boolean' })
  collisionEnabled?: boolean

  @ApiProperty({ type: 'string' })
  shapeType: string

  @ApiProperty({ type: 'string' })
  bodyType: string

  // Deprecated but kept for compat, remove in the future.
  @ApiProperty({ type: 'boolean' })
  staticEnabled?: boolean

  @ApiProperty({ type: Number })
  massKg?: number

  @ApiProperty({ type: Number })
  gravityScale?: number

  @ApiProperty({ type: 'string' })
  materialAssetId: string

  @ApiProperty({ type: Array })
  objectColor: Vector3AsArray

  @ApiProperty({ type: 'string' })
  objectTexture: string

  @ApiProperty({ type: Number })
  objectTextureSize: number

  @ApiProperty({ type: Number })
  objectTextureSizeV2: number

  @ApiProperty({ type: Number })
  objectTextureOffset: number

  @ApiProperty({ type: 'boolean' })
  objectTextureTriplanar: boolean

  @ApiProperty({ type: 'boolean' })
  objectTextureRepeat: boolean

  @ApiProperty({ type: 'boolean' })
  audioAutoPlay: boolean

  @ApiProperty({ type: 'boolean' })
  audioLoop: boolean

  @ApiProperty({ type: 'boolean' })
  audioIsSpatial: boolean

  @ApiProperty({ type: Number })
  audioPitch?: number

  @ApiProperty({ type: Number })
  audioBaseVolume?: number

  @ApiProperty({ type: Number })
  audioSpatialMaxVolume?: number

  @ApiProperty({ type: Number })
  audioSpatialRange?: number

  @ApiProperty({ type: Array })
  surfaceMaterialId?: any[]

  @ApiProperty({ type: Array })
  scriptEvents?: any[]

  @ApiProperty({ type: Array })
  extraNodes?: any[]

  @ApiProperty({ type: 'string' })
  _id: string

  @ApiProperty({ type: Object })
  tags: Tags
}

export type SpaceObjectDocument = SpaceObject & Document

@Schema({
  timestamps: true,
  toJSON: {
    virtuals: true
  },
  strict: false // allowed while we figure out the final schema and/or possibly refactor.
})
export class SpaceObject {
  @Prop({
    required: true,
    default: 'A Newly-Created Space Object Instance'
  })
  @ApiProperty()
  name: string

  @Prop()
  @ApiProperty()
  description?: string

  @Prop({
    required: false, // TODO: sent true once the GD server logic is there. (Apr 27 2023)
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  })
  @ApiProperty()
  creator: User

  @Prop({
    required: true,
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Asset'
  })
  @ApiProperty()
  asset: Asset

  @Prop({ type: mongoose.Schema.Types.ObjectId, ref: 'CustomData' })
  @ApiProperty()
  customData: CustomData

  @Prop({
    required: false,
    type: RoleSchema
  })
  @ApiProperty()
  role: Role

  @Prop({
    required: false,
    type: mongoose.Schema.Types.ObjectId,
    ref: 'SpaceObject'
  })
  @ApiProperty()
  parentSpaceObject?: mongoose.Schema.Types.ObjectId

  @Prop({
    required: true,
    default: false
  })
  @ApiProperty()
  isGroup?: boolean

  @Prop()
  @ApiProperty()
  parentId?: string

  @Prop({ required: true, type: mongoose.Schema.Types.ObjectId, ref: 'Space' })
  @ApiProperty()
  space: Space

  @Prop({
    required: false,
    default: false
  })
  @ApiProperty()
  locked: boolean

  /**
   * @description This is used to determine if the object should be loaded before the space starts. This is useful for objects that are used as Maps that need to be loaded before the user enters
   * @date 2023-06-05 12:51
   */
  @Prop()
  @ApiProperty()
  preloadBeforeSpaceStarts?: boolean

  // Transform properties.
  @Prop({
    required: true,
    default: [0.0, 0.0, 0.0],
    type: mongoose.Types.Array
  })
  @ApiProperty()
  position: Vector3AsArray

  @Prop({
    required: true,
    default: [0.0, 0.0, 0.0],
    type: mongoose.Types.Array
  })
  @ApiProperty()
  rotation: Vector3AsArray

  @Prop({
    required: true,
    default: [1.0, 1.0, 1.0],
    type: mongoose.Types.Array
  })
  @ApiProperty()
  scale: Vector3AsArray

  @Prop({
    required: true,
    default: [0.0, 0.0, 0.0],
    type: mongoose.Types.Array
  })
  @ApiProperty()
  offset: Vector3AsArray

  // Physics properties.
  @Prop({
    required: false,
    default: null
  })
  @ApiProperty()
  collisionEnabled?: boolean

  @Prop({
    required: false,
    default: 'Auto'
  })
  @ApiProperty()
  shapeType: string

  @Prop({
    required: false,
    default: 'Static'
  })
  @ApiProperty()
  bodyType: string

  // Deprecated but kept for compat, remove in the future.
  @Prop({
    required: false,
    default: null
  })
  @ApiProperty()
  staticEnabled?: boolean

  @Prop({
    required: false,
    default: null
  })
  @ApiProperty()
  massKg?: number

  @Prop({
    required: false,
    default: null
  })
  @ApiProperty()
  gravityScale?: number

  // Visibility properties
  @Prop({
    required: false,
    default: true,
    type: Boolean
  })
  @ApiProperty()
  castShadows?: boolean

  @Prop({
    required: false,
    default: 0.0,
    type: Number
  })
  @ApiProperty()
  visibleFrom?: number

  @Prop({
    required: false,
    default: 0.0,
    type: Number
  })
  @ApiProperty()
  visibleTo?: number

  @Prop({
    required: false,
    default: 0.0,
    type: Number
  })
  @ApiProperty()
  visibleFromMargin?: number

  @Prop({
    required: false,
    default: 0.0,
    type: Number
  })
  @ApiProperty()
  visibleToMargin?: number

  // Material property. This references an Asset
  @Prop({
    required: false,
    default: ''
  })
  @ApiProperty()
  materialAssetId: string

  // Instance material properties. Defines the set of material parameters
  // that can be changed per individual SpaceObject instance
  @Prop({
    required: false,
    default: [1.0, 1.0, 1.0, 1.0],
    type: mongoose.Types.Array
  })
  @ApiProperty()
  objectColor: Vector4AsArray

  @Prop({
    required: false,
    default: ''
  })
  @ApiProperty()
  objectTexture: string

  /**
   * @deprecated
   * @description objectTextureSize was updated to objectTextureSizeV2 using Vector3. 2023-04-17
   */
  @Prop({
    required: false,
    default: 1.0
  })
  @ApiProperty()
  objectTextureSize: number

  @Prop({
    required: false,
    default: [1.0, 1.0, 1.0],
    type: mongoose.Types.Array
  })
  @ApiProperty()
  objectTextureSizeV2: Vector3AsArray

  @Prop({
    required: false,
    default: [0.0, 0.0, 0.0],
    type: mongoose.Types.Array
  })
  @ApiProperty()
  objectTextureOffset: Vector3AsArray

  @Prop({
    required: false,
    default: false
  })
  @ApiProperty()
  objectTextureTriplanar: boolean

  @Prop({
    required: false,
    default: true
  })
  @ApiProperty()
  objectTextureRepeat: boolean

  // Audio properties.
  @Prop({
    required: false,
    default: true
  })
  @ApiProperty()
  audioAutoPlay?: boolean

  @Prop({
    required: false,
    default: true
  })
  @ApiProperty()
  audioLoop?: boolean

  @Prop({
    required: false,
    default: true
  })
  @ApiProperty()
  audioIsSpatial?: boolean

  @Prop({
    required: false,
    default: 100.0
  })
  @ApiProperty()
  audioPitch?: number

  @Prop({
    required: false,
    default: 100.0
  })
  @ApiProperty()
  audioBaseVolume?: number

  @Prop({
    required: false,
    default: 150.0
  })
  @ApiProperty()
  audioSpatialMaxVolume?: number

  @Prop({
    required: false,
    default: 0.0
  })
  @ApiProperty()
  audioSpatialRange?: number

  @Prop([mongoose.Schema.Types.Array])
  @ApiProperty()
  surfaceMaterialId: any[]

  @Prop([mongoose.Schema.Types.Map])
  @ApiProperty()
  scriptEvents: any[]

  @Prop([mongoose.Schema.Types.Map])
  @ApiProperty()
  extraNodes: any[]

  @ApiProperty()
  _id: string

  @Prop({ type: TagsSchema, required: false, default: {} })
  @ApiProperty()
  tags: Tags
}

export const SpaceObjectSchema = SchemaFactory.createForClass(SpaceObject)

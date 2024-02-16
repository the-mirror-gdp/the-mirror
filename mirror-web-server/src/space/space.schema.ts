import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose'
import { ApiProperty } from '@nestjs/swagger'
import * as mongoose from 'mongoose'
import { Document } from 'mongoose'
import { CustomData } from '../custom-data/models/custom-data.schema'
import { SPACE_TYPE } from '../option-sets/space'
import { SPACE_TEMPLATE } from '../option-sets/space-templates'
import { Role, RoleSchema } from '../roles/models/role.schema'
import { User } from '../user/user.schema'
import { SpaceVersion } from './space-version.schema'
import {
  MaterialInstance,
  MaterialInstanceSchema
} from './material-instance/material-instance.schema'
import { ROLE } from '../roles/models/role.enum'
import { BUILD_PERMISSIONS } from '../option-sets/build-permissions'
import { Tags, TagsSchema } from '../tag/models/tags.schema'
import { ISpaceServer } from './abstractions/space-server.interface'

export type SpaceDocument = Space & Document

export class SpacePublicData {
  @ApiProperty({ type: 'string' }) // @ApiProperty must be included to be exposed by the API and flow to FE codegen
  _id = '' // Must not be undefined
  @ApiProperty({ type: Date })
  createdAt = new Date()
  @ApiProperty({ type: Date })
  updatedAt = new Date()
  @ApiProperty({
    anyOf: [
      {
        $ref: '#/components/schemas/User' // There may be a better way to do this? But this DOES work for FE codegen.
      }
      // { type: 'string' }
    ]
  })
  creator: User
  @ApiProperty({ type: 'string' })
  activeSpaceVersion?: string | SpaceVersion | mongoose.Schema.Types.ObjectId =
    ''
  @ApiProperty({ type: 'string' })
  name = ''
  @ApiProperty({ type: 'string' })
  description = ''
  @ApiProperty({ type: Tags })
  tags = {}
  @ApiProperty({ type: ['string'] })
  scriptIds = []
  @ApiProperty({ type: [mongoose.Schema.Types.Map] })
  scriptInstances: any[] = []
  @ApiProperty({ type: [mongoose.Schema.Types.Map] })
  materialInstances?: any[] = []
  @ApiProperty({ type: ['string'] })
  images = []
  @ApiProperty({ type: 'string' })
  type = ''
  @ApiProperty({ type: 'string' })
  role: Role
  @ApiProperty({ enum: SPACE_TEMPLATE })
  template = ''
  @ApiProperty({ enum: BUILD_PERMISSIONS })
  publicBuildPermissions = ''
  @ApiProperty({
    type: 'number',
    required: false
  })
  AVG_RATING = null
  @ApiProperty({
    type: 'number',
    required: false
  })
  COUNT_LIKE = 0
  @ApiProperty({
    type: 'number',
    required: false
  })
  COUNT_FOLLOW = 0
  @ApiProperty({
    type: 'number',
    required: false
  })
  COUNT_SAVES = 0
  @ApiProperty({
    type: 'number',
    required: false
  })
  COUNT_RATING = 0
  @ApiProperty({
    type: 'number',
    required: false
  })
  usersCount = 0
  @ApiProperty({
    type: 'object',
    required: false
  })
  servers = {}
  @ApiProperty({
    type: 'array',
    required: false
  })
  usersPresent = []
  @ApiProperty({ type: 'array' })
  previousUsers: mongoose.Types.ObjectId[]
}

@Schema({
  timestamps: true,
  toJSON: {
    virtuals: true
  }
})
export class Space {
  @Prop({ required: true })
  @ApiProperty()
  name: string

  @Prop()
  @ApiProperty()
  description: string

  @Prop([String])
  @ApiProperty()
  images: string[]

  @Prop([String])
  @ApiProperty()
  scriptIds: string[]

  @Prop([mongoose.Schema.Types.Map])
  @ApiProperty()
  scriptInstances: any[]

  @Prop({
    required: false,
    type: [MaterialInstanceSchema],
    select: false
  })
  @ApiProperty()
  materialInstances?: MaterialInstance[]

  @Prop({
    required: true,
    default: SPACE_TYPE.MATCH,
    type: String,
    enum: SPACE_TYPE
  })
  @ApiProperty({ enum: SPACE_TYPE })
  type: SPACE_TYPE

  @Prop({ type: mongoose.Schema.Types.ObjectId, ref: 'SpaceVersion' })
  @ApiProperty()
  activeSpaceVersion?: mongoose.Schema.Types.ObjectId

  @Prop({ type: mongoose.Schema.Types.ObjectId, ref: 'CustomData' })
  @ApiProperty()
  customData: CustomData

  @Prop({ type: mongoose.Schema.Types.ObjectId, ref: 'SpaceVariablesData' })
  @ApiProperty()
  spaceVariablesData: mongoose.Schema.Types.ObjectId

  @Prop({
    default: -200
  })
  @ApiProperty()
  lowerLimitY: number

  /**
   * @deprecated use fromTemplate instead. This was an old enum string field that was never used
   * @date 2023-07-20 16:07
   */
  @Prop({
    required: false,
    default: SPACE_TEMPLATE.MARS,
    type: String,
    enum: SPACE_TEMPLATE
  })
  @ApiProperty({ enum: SPACE_TEMPLATE })
  template: SPACE_TEMPLATE

  /**
   * @description If the Space was created from a template, then use this field to store the original Space's _id
   * @date 2023-07-20 16:10
   */
  @Prop({
    required: false,
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Space'
  })
  @ApiProperty()
  fromTemplate: mongoose.Schema.Types.ObjectId

  @Prop({
    required: false,
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Terrain'
  })
  @ApiProperty()
  terrain: mongoose.Schema.Types.ObjectId

  @Prop({
    required: false,
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Environment'
  })
  @ApiProperty()
  environment: mongoose.Schema.Types.ObjectId

  @Prop({
    required: true,
    type: RoleSchema
  })
  @ApiProperty()
  role: Role

  @Prop({
    required: true,
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  })
  @ApiProperty()
  creator: mongoose.Schema.Types.ObjectId

  @ApiProperty()
  createdAt: Date

  @ApiProperty()
  updatedAt: Date

  @ApiProperty()
  _id: string

  @Prop({ type: TagsSchema, required: false, default: {} })
  @ApiProperty()
  tags: Tags

  @Prop({
    type: Boolean,
    required: false
  })
  @ApiProperty()
  isTMTemplate?: boolean

  /**
   * @description This field specifies the maximum number of users on the server.
   * @date 2023-11-01
   */
  @Prop({
    type: Number,
    required: true
  })
  @ApiProperty()
  maxUsers: number

  @Prop({ type: Number, required: false })
  @ApiProperty()
  AVG_RATING?: number

  @Prop({ type: Number, required: false })
  @ApiProperty()
  COUNT_FOLLOW?: number

  @Prop({ type: Number, required: false })
  @ApiProperty()
  COUNT_RATING?: number

  @Prop({ type: Number, required: false })
  @ApiProperty()
  COUNT_LIKE?: number

  @Prop({ type: Number, required: false })
  @ApiProperty()
  COUNT_SAVES?: number

  @Prop({ type: Number, required: false })
  @ApiProperty()
  usersCount?: number

  @Prop({ type: [mongoose.Types.ObjectId], required: false, ref: 'User' })
  @ApiProperty()
  usersPresent?: mongoose.Types.ObjectId[]

  @Prop({ type: mongoose.Types.Map, required: false })
  @ApiProperty()
  servers?: ISpaceServer

  //Techical debt: should be moved to a role schema
  @Prop({
    type: String,
    required: true,
    enum: Object.values(BUILD_PERMISSIONS),
    default: BUILD_PERMISSIONS.OBSERVER
  })
  @ApiProperty({ enum: () => BUILD_PERMISSIONS })
  publicBuildPermissions: BUILD_PERMISSIONS

  @Prop({ type: [mongoose.Types.ObjectId], required: false, ref: 'User' })
  @ApiProperty()
  previousUsers: mongoose.Types.ObjectId[]

  @Prop({
    type: mongoose.Types.ObjectId,
    required: true,
    ref: 'MirrorDBRecord'
  })
  @ApiProperty()
  mirrorDBRecord: mongoose.Types.ObjectId

  @Prop({ type: [String], required: false })
  @ApiProperty()
  kickRequests: string[]
}

export const SpaceSchema = SchemaFactory.createForClass(Space)

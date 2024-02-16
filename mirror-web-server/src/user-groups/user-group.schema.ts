import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose'
import { ApiProperty } from '@nestjs/swagger'
import * as mongoose from 'mongoose'
import { Document } from 'mongoose'
import { User, UserPublicData } from '../user/user.schema'

// Properties must not be undefined so that getPublicPropertiesForMongooseQuery can work
export class UserGroupPublicData {
  @ApiProperty() // @ApiProperty must be included to be exposed by the API and flow to FE codegen
  _id = '' // Must not be undefined
  @ApiProperty()
  createdAt = new Date()
  @ApiProperty()
  updatedAt = new Date()
  @ApiProperty()
  name = ''
  @ApiProperty()
  public = true
  @ApiProperty()
  discordUrl = ''
  @ApiProperty()
  ethereumDaoContractPublicKey = ''
  @ApiProperty()
  polygonDaoContractPublicKey = ''
  @ApiProperty({
    type: () => UserPublicData
  })
  owners = [new UserPublicData()]
  @ApiProperty()
  image = ''

  @ApiProperty()
  publicDescription = ''

  @ApiProperty()
  twitterUrl = ''

  @ApiProperty()
  websiteUrl = ''
}

export type UserGroupDocument = UserGroup & Document

@Schema({
  timestamps: true,
  toJSON: {
    virtuals: true
  }
})
export class UserGroup {
  @ApiProperty()
  _id: string
  @ApiProperty()
  createdAt: Date // this is managed by mongoose timestamps: true, but defining it here so types will align
  @ApiProperty()
  updatedAt: Date // this is managed by mongoose timestamps: true, but defining it here so types will align

  @Prop()
  @ApiProperty()
  name: string

  @Prop({
    default: true
  })
  @ApiProperty()
  public: string

  @Prop()
  @ApiProperty()
  discordUrl: string

  @Prop()
  @ApiProperty()
  ethereumDaoContractPublicKey: string

  @Prop()
  @ApiProperty()
  polygonDaoContractPublicKey: string

  @Prop({ type: [mongoose.Schema.Types.ObjectId], ref: 'User' })
  @ApiProperty()
  moderators: User[]

  @Prop({ type: [mongoose.Schema.Types.ObjectId], ref: 'User' })
  @ApiProperty()
  owners: User[]

  @Prop({
    required: true
  })
  @Prop({ type: mongoose.Schema.Types.ObjectId, ref: 'User' })
  @ApiProperty()
  primaryContact: User

  @Prop()
  @ApiProperty()
  image: string // url

  @Prop()
  @ApiProperty()
  publicDescription: string

  @Prop()
  @ApiProperty()
  twitterUrl: string

  @Prop({ type: [mongoose.Schema.Types.ObjectId], ref: 'User' })
  @ApiProperty()
  users: User[]

  @Prop()
  @ApiProperty()
  websiteUrl: string

  @Prop({ type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true })
  @ApiProperty()
  creator: User
}

export const UserGroupSchema = SchemaFactory.createForClass(UserGroup)

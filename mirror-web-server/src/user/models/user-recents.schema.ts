import * as mongoose from 'mongoose'
import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose'
import { ApiProperty } from '@nestjs/swagger'

export type UserRecentsDocument = UserRecents & Document

export interface IUserRecents {
  spaces?: string[]
  assets?: IUserRecentsAssets
  scripts?: string[]
}

interface IUserRecentsAssets {
  instanced: string[]
}

@Schema({
  timestamps: false,
  toJSON: {
    virtuals: true
  },
  _id: false
})
export class UserRecentAssets {
  @Prop({
    type: [mongoose.Schema.Types.ObjectId],
    default: [],
    ref: 'Asset',
    select: false
  })
  @ApiProperty({
    description: 'A list of 10 user`s recent assets'
  })
  instanced?: string[]
}

export const UserRecentAssetsSchema =
  SchemaFactory.createForClass(UserRecentAssets)

@Schema({
  timestamps: false,
  toJSON: {
    virtuals: true
  },
  _id: false
})
export class UserRecents {
  @Prop({
    type: [mongoose.Schema.Types.ObjectId],
    default: [],
    ref: 'Space',
    select: false
  })
  @ApiProperty({
    description: 'A list of 10 user`s recent spaces'
  })
  spaces?: string[]

  @Prop({
    default: {},
    type: UserRecentAssets
  })
  @ApiProperty()
  assets: UserRecentAssets

  @Prop({
    type: [mongoose.Schema.Types.ObjectId],
    default: [],
    ref: 'ScriptEntity',
    select: false
  })
  @ApiProperty({
    description: 'A list of 10 user`s recent scripts'
  })
  scripts?: string[]
}

export const UserRecentsSchema = SchemaFactory.createForClass(UserRecents)

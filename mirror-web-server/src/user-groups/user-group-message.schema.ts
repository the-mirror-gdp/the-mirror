import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose'
import { ApiProperty } from '@nestjs/swagger'
import * as mongoose from 'mongoose'
import { Document } from 'mongoose'
import { User } from '../user/user.schema'
import { UserGroup } from './user-group.schema'

export type UserGroupMessageDocument = UserGroupMessage & Document

@Schema({
  timestamps: true,
  toJSON: {
    virtuals: true
  }
})
export class UserGroupMessage {
  @Prop({ type: mongoose.Schema.Types.ObjectId, ref: 'UserGroup' })
  @ApiProperty({ type: () => UserGroup })
  group: UserGroup

  @Prop({
    required: true,
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  })
  @ApiProperty({ type: () => User })
  creator: User

  @Prop({
    required: true
  })
  @ApiProperty()
  messageText: string
}

export const UserGroupMessageSchema =
  SchemaFactory.createForClass(UserGroupMessage)

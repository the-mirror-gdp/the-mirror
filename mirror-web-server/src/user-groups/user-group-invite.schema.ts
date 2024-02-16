import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose'
import { ApiProperty } from '@nestjs/swagger'
import * as mongoose from 'mongoose'
import { Document } from 'mongoose'
import { USER_GROUP_INVITE_STATUSES } from '../option-sets/user-group-invite-statuses'
import { User } from '../user/user.schema'
import { UserGroup } from './user-group.schema'

export type UserGroupInviteDocument = UserGroupInvite & Document

@Schema({
  timestamps: true,
  toJSON: {
    virtuals: true
  }
})
export class UserGroupInvite {
  @Prop({ type: mongoose.Schema.Types.ObjectId, ref: 'UserGroup' })
  @ApiProperty()
  group: UserGroup

  @Prop()
  @ApiProperty()
  unlimited: boolean

  @Prop()
  @ApiProperty()
  used: boolean

  @Prop({
    required: true,
    default: USER_GROUP_INVITE_STATUSES.INVITE_PENDING,
    type: String
  })
  @ApiProperty()
  status: string

  @Prop({
    required: true
  })
  @ApiProperty()
  completed: boolean

  @Prop({
    required: true,
    default: new Date()
  })
  @ApiProperty()
  completedDate: Date

  @Prop({
    required: true,
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  })
  @ApiProperty()
  creator: mongoose.Schema.Types.ObjectId

  @Prop({
    required: true,
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  })
  @ApiProperty()
  recipient: mongoose.Schema.Types.ObjectId
}

export const userGroupInvite = SchemaFactory.createForClass(UserGroupInvite)

import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose'
import { ApiProperty } from '@nestjs/swagger'
import * as mongoose from 'mongoose'
import { Document } from 'mongoose'
import { GROUP_ROLE } from '../option-sets/group-users-roles'
import { USER_GROUP_MEMBERSHIP_STATUSES } from '../option-sets/user-group-membership-statuses'
import { User } from '../user/user.schema'
import { UserGroup } from './user-group.schema'

export type UserGroupMembershipDocument = UserGroupMembership & Document

@Schema({
  timestamps: true,
  toJSON: {
    virtuals: true
  }
})
export class UserGroupMembership {
  @Prop({ type: mongoose.Schema.Types.ObjectId, ref: 'UserGroup' })
  @ApiProperty()
  group: UserGroup

  @Prop({
    required: true,
    default: USER_GROUP_MEMBERSHIP_STATUSES.PENDING,
    type: String
  })
  @ApiProperty()
  status: USER_GROUP_MEMBERSHIP_STATUSES

  @Prop({
    required: true,
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  })
  @ApiProperty()
  creator: User

  @Prop({
    required: true,
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  })
  @ApiProperty({ type: () => User })
  user: User

  @Prop({
    required: true,
    default: new Date()
  })
  @ApiProperty()
  expirationDate: Date

  /**
   * @description Whether non-members (the public) can see that the user is a member of this group
   */
  @Prop({
    default: true
  })
  @ApiProperty()
  membershipIsPubliclyVisible: boolean
}

export const UserGroupMembershipSchema =
  SchemaFactory.createForClass(UserGroupMembership)

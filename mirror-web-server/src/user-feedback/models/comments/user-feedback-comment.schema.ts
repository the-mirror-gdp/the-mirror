import * as mongoose from 'mongoose'
import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose'
import { ApiProperty } from '@nestjs/swagger'
import { User } from '../../../user/user.schema'
import { USER_FEEDBACK_ITEM_TYPE } from '../../../option-sets/user-feedback'
import { UserFeedbackItem } from '../user-feedback/user-feedback-item.schema'
import { Role, RoleSchema } from '../../../roles/models/role.schema'
import { ISchemaWithRole } from '../../../roles/role-consumer.interface'

export class UserFeedbackCommentPublicData {
  @ApiProperty()
  name = ''
  @ApiProperty()
  public = false
  @ApiProperty()
  UserFeedbackType = USER_FEEDBACK_ITEM_TYPE.FEATURE_REQUEST // ONLY used for the API. We don't store UserFeedbackEType in the document bc it's redundant with the discriminator key, __t
  @ApiProperty()
  creator = ''
}

export type UserFeedbackCommentDocument = UserFeedbackItem & Document

/**
 * @description This class should not be used by itself. It is the base class for all UserFeedbackItem types. Generally, UserFeedbackItemFeatureRequest and UserFeedbackItemBug should be used.
 * @date 2023-02-17 16:01
 */
@Schema({
  timestamps: true,
  toJSON: {
    virtuals: true
  }
})
export class UserFeedbackComment {
  @Prop({ required: true })
  @ApiProperty({
    description: 'Public-facing text of the UserFeedbackComment'
  })
  text: string

  @Prop({
    required: function () {
      return !this.groupOwned
    },
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  })
  @ApiProperty({
    description: 'The individual owner.'
  })
  owner: User

  @Prop({ type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true })
  @ApiProperty()
  creator: User

  @Prop({
    type: mongoose.Schema.Types.ObjectId,
    ref: 'UserFeedbackItem',
    required: true
  })
  @ApiProperty()
  userFeedbackItem: UserFeedbackItem

  @Prop({ default: false })
  @ApiProperty({
    description:
      'Admin-only toggle whether this comment is hidden from the public (e.g. if we need to moderate content)'
  })
  adminHidden: boolean

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
   * @description This will never be true for a userfeedbackitem (business logic), it's just required by ISchemaWithRole. We could add a groupOwned UserFeedbackItem if we really wanted to though.
   * @date 2023-04-01 00:40
   */
  @Prop({ default: false })
  groupOwned: boolean

  @ApiProperty()
  _id: string

  // Virtual: implemented below
  userIsOwner: any
  /**
   * END Section: ISchemaWithRole implementer
   */
}

export const UserFeedbackCommentSchema =
  SchemaFactory.createForClass(UserFeedbackComment)

UserFeedbackCommentSchema.methods.userIsOwner = function (
  userId: string
): boolean {
  // ensure userId is not undefined/falsey. undefined===undefined can slip through checks
  if (!userId) {
    return false
  }
  if (this.owner === userId || this.owner?._id?.toString() === userId) {
    // individual owner
    return true
  }

  return false
}

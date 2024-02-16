import * as mongoose from 'mongoose'
import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose'
import { ApiProperty } from '@nestjs/swagger'
import { User } from '../../../user/user.schema'
import {
  USER_FEEDBACK_ITEM_STATUS,
  USER_FEEDBACK_ITEM_TYPE
} from '../../../option-sets/user-feedback'
import { Role, RoleSchema } from '../../../roles/models/role.schema'
import { ISchemaWithRole } from '../../../roles/role-consumer.interface'

export class UserFeedbackItemPublicData {
  @ApiProperty()
  name = ''
  @ApiProperty()
  description = ''
  @ApiProperty()
  public = false
  @ApiProperty()
  creator = ''
  @ApiProperty()
  status = USER_FEEDBACK_ITEM_STATUS.OPEN
  @ApiProperty()
  userFeedbackType = USER_FEEDBACK_ITEM_TYPE.FEATURE_REQUEST // ONLY used for the API. We don't store UserFeedbackEType in the document bc it's redundant with the discriminator key, __t
}

export type UserFeedbackItemDocument = UserFeedbackItem & mongoose.Document

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
export class UserFeedbackItem {
  @Prop({ required: true })
  @ApiProperty({
    description: 'Public-facing name of the UserFeedbackItem'
  })
  name: string

  @Prop({ required: false })
  @ApiProperty({
    description: 'Public-facing description of the UserFeedbackItem'
  })
  description: string

  @Prop({ required: true, default: true })
  @ApiProperty({
    description: 'Whether this item is displayed publicly'
  })
  public: boolean

  @Prop({
    required: true,
    default: USER_FEEDBACK_ITEM_STATUS.OPEN,
    enum: Object.values(USER_FEEDBACK_ITEM_STATUS),
    type: String
  })
  @ApiProperty({
    description: 'The public status of this UserFeedbackItem'
  })
  status: string

  // Creator and owner will be the same for this, it just follows the same pattern as our other entities
  @Prop({ type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true })
  @ApiProperty()
  creator: User
  @Prop({ type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true })
  @ApiProperty()
  owner: mongoose.Schema.Types.ObjectId

  @Prop({
    type: [mongoose.Schema.Types.ObjectId],
    ref: 'User',
    required: true,
    default: []
  })
  @ApiProperty()
  upvotedBy: mongoose.Schema.Types.ObjectId[]

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

  userIsOwner: any
  /**
   * END Section: ISchemaWithRole implementer
   */
}

export const UserFeedbackItemSchema =
  SchemaFactory.createForClass(UserFeedbackItem)

UserFeedbackItemSchema.methods.userIsOwner = function (
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

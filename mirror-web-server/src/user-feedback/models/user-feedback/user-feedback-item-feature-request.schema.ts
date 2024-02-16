import { Schema, SchemaFactory } from '@nestjs/mongoose'
import {
  UserFeedbackItem,
  UserFeedbackItemPublicData
} from './user-feedback-item.schema'

export class UserFeedbackItemFeatureRequestPublicData extends UserFeedbackItemPublicData {}

export type UserFeedbackItemFeatureRequestDocument =
  UserFeedbackItemFeatureRequest & Document

/**
 * @description User feedback for a feature. This will generally be displayed publicly
 * @date 2023-02-17 16:03:29
 */
@Schema({
  timestamps: true,
  toJSON: {
    virtuals: true
  }
  // discriminatorKey: __t <- don't uncomment this line: this line is to note that __t is the Mongoose default discriminator key that we use for simplicity rather than specifying our own discriminator key. When this schema is instantiated, __t is "UserFeedbackItemFeatureRequest". See https://mongoosejs.com/docs/discriminators.html#discriminator-keys. Walkthrough: https://www.loom.com/share/7e09d2777ef94368bcd5fd8c8341b5ef
})
export class UserFeedbackItemFeatureRequest extends UserFeedbackItem {}

export const UserFeedbackItemFeatureRequestSchema =
  SchemaFactory.createForClass(UserFeedbackItemFeatureRequest)

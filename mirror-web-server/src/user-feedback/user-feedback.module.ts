import { LoggerModule } from './../util/logger/logger.module'
import { Module } from '@nestjs/common'
import { MongooseModule } from '@nestjs/mongoose'
import { RoleModule } from '../roles/role.module'
import {
  UserFeedbackComment,
  UserFeedbackCommentSchema
} from './models/comments/user-feedback-comment.schema'
import {
  UserFeedbackItemBug,
  UserFeedbackItemBugSchema
} from './models/user-feedback/user-feedback-item-bug.schema'
import {
  UserFeedbackItemFeatureRequest,
  UserFeedbackItemFeatureRequestSchema
} from './models/user-feedback/user-feedback-item-feature-request.schema'
import {
  UserFeedbackItem,
  UserFeedbackItemSchema
} from './models/user-feedback/user-feedback-item.schema'
import { UserFeedbackController } from './user-feedback.controller'
import { UserFeedbackService } from './user-feedback.service'

@Module({
  imports: [
    RoleModule,
    LoggerModule,
    MongooseModule.forFeature([
      {
        name: UserFeedbackItem.name,
        schema: UserFeedbackItemSchema,
        discriminators: [
          {
            name: UserFeedbackItemFeatureRequest.name,
            schema: UserFeedbackItemFeatureRequestSchema
          },
          {
            name: UserFeedbackItemBug.name,
            schema: UserFeedbackItemBugSchema
          }
        ]
      },
      // This is NOT a subclass of UserFeedbackItem. It's a separate collection since it's just used for comments on UserFeedbackItems
      { name: UserFeedbackComment.name, schema: UserFeedbackCommentSchema }
    ])
  ],
  controllers: [UserFeedbackController],
  providers: [UserFeedbackService]
})
export class UserFeedbackModule {}

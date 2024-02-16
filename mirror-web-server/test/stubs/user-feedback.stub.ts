import { CreateUserFeedbackCommentDto } from './../../src/user-feedback/dto/create-user-feedback-comment.dto'
import { CreateUserFeedbackItemDto } from './../../src/user-feedback/dto/create-user-feedback.dto'
import { SPACE_TYPE } from '../../src/option-sets/space'
import { SPACE_TEMPLATE } from '../../src/option-sets/space-templates'
import { ROLE } from '../../src/roles/models/role.enum'
import { CreateSpaceDto } from '../../src/space/dto/create-space.dto'
import { ModelStub } from './model.stub'
import { USER_FEEDBACK_ITEM_TYPE } from '../../src/option-sets/user-feedback'

// Util: mongo object ID generator: https://observablehq.com/@hugodf/mongodb-objectid-generator

export class UserFeedbackModelStub extends ModelStub {}

/**
 * Item 1
 */
export const userFeedbackItemFeature1ToBeCreated: CreateUserFeedbackItemDto = {
  name: 'userFeedbackItem1ToBeCreated',
  description: 'description userFeedbackItem1ToBeCreated',
  userFeedbackType: USER_FEEDBACK_ITEM_TYPE.FEATURE_REQUEST
}
/**
 * Item 3
 */
export const userFeedbackItemBug3ToBeCreated: CreateUserFeedbackItemDto = {
  name: 'userFeedbackItem3ToBeCreated',
  description: 'description userFeedbackItem3ToBeCreated',
  userFeedbackType: USER_FEEDBACK_ITEM_TYPE.BUG
}

/**
 * Comment 2
 */
export const userFeedbackComment2ToBeCreated: Omit<
  CreateUserFeedbackCommentDto,
  'userFeedbackItemId'
> = {
  text: 'text comment userFeedbackComment2ToBeCreated'
}

import { PartialType } from '@nestjs/swagger'
import { CreateUserFeedbackItemDto } from './create-user-feedback.dto'

export class UpdateUserFeedbackDto extends PartialType(
  CreateUserFeedbackItemDto
) {}

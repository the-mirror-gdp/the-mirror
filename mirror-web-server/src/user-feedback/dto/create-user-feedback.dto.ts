import { ApiProperty } from '@nestjs/swagger'
import {
  IsBoolean,
  IsEnum,
  IsNotEmpty,
  IsOptional,
  IsString
} from 'class-validator'
import {
  USER_FEEDBACK_ITEM_STATUS,
  USER_FEEDBACK_ITEM_TYPE,
  USER_FEEDBACK_ITEM_VOTE
} from '../../option-sets/user-feedback'

export class CreateUserFeedbackItemDto {
  @IsNotEmpty()
  @IsString()
  @ApiProperty()
  name: string

  /**
   * Optional
   */
  @IsOptional()
  @IsString()
  @ApiProperty()
  description?: string

  @IsOptional()
  @IsEnum(USER_FEEDBACK_ITEM_TYPE)
  @ApiProperty({
    enum: USER_FEEDBACK_ITEM_TYPE,
    description: `Status the discriminator/subclass of the UserFeedbackItem, such as feature request or bug. Optional: defaults to USER_FEEDBACK_TYPE.FEATURE_REQUEST. Options: ${Object.values(
      USER_FEEDBACK_ITEM_TYPE
    ).join(', ')}'}`
  })
  userFeedbackType?: string

  @IsOptional()
  @IsEnum(USER_FEEDBACK_ITEM_STATUS)
  @ApiProperty({
    enum: USER_FEEDBACK_ITEM_STATUS,
    description: `Status of the UserFeedbackItem, such as feature request or bug. Optional: defaults to USER_FEEDBACK_ITEM_STATUS.OPEN. Options: ${Object.values(
      USER_FEEDBACK_ITEM_STATUS
    ).join(', ')}'}`
  })
  USER_FEEDBACK_ITEM_STATUS?: string

  @IsOptional()
  @IsBoolean()
  @ApiProperty()
  public?: boolean
}

export class CreateVoteOnUserFeedbackItemDto {
  @IsNotEmpty()
  @IsString()
  @ApiProperty()
  userFeedbackItemId: string

  @IsNotEmpty()
  @IsEnum(USER_FEEDBACK_ITEM_VOTE)
  @ApiProperty()
  vote: string
}

export class CreateUserFeedbackItemFeatureRequestDto extends CreateUserFeedbackItemDto {}

export class CreateUserFeedbackItemBugDto extends CreateUserFeedbackItemDto {}

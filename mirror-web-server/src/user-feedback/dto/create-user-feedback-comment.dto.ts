import { ApiProperty } from '@nestjs/swagger'
import { IsNotEmpty, IsString } from 'class-validator'

export class CreateUserFeedbackCommentDto {
  @IsNotEmpty()
  @IsString()
  @ApiProperty()
  text: string

  @IsNotEmpty()
  @IsString()
  @ApiProperty()
  userFeedbackItemId: string
}

import { ApiProperty } from '@nestjs/swagger'
import { IsNotEmpty, IsString, MaxLength, MinLength } from 'class-validator'
export class CreateGodotServerOverrideConfigDto {
  @IsNotEmpty()
  @IsString()
  @MinLength(24, {
    message: 'A Mongo ObjectId is 24 characters'
  })
  @MaxLength(24, {
    message: 'A Mongo ObjectId is 24 characters'
  })
  @ApiProperty({
    required: true,
    type: String
  })
  spaceId: string
}

import { ApiProperty } from '@nestjs/swagger'
import { IsNotEmpty, IsString } from 'class-validator'

export class SubmitUserAccessKeyDto {
  @IsNotEmpty()
  @IsString()
  @ApiProperty()
  key: string
}

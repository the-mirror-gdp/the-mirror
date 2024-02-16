import { ApiProperty } from '@nestjs/swagger'
import { IsEnum, IsNotEmpty, IsString } from 'class-validator'

export class CreateAuthDto {
  @IsString()
  @IsNotEmpty()
  @ApiProperty()
  firebaseUid: string
}

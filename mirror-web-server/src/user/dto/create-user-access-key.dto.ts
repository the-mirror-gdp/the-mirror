import { ApiProperty } from '@nestjs/swagger'
import { IsNotEmpty, IsString, IsOptional } from 'class-validator'

export class CreateUserAccessKeyDto {
  @IsNotEmpty()
  @IsString()
  @ApiProperty()
  token: string

  @IsOptional()
  @IsString()
  @ApiProperty()
  adminNote: string
}

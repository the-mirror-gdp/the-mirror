import { ApiProperty } from '@nestjs/swagger'
import {
  IsBoolean,
  IsEnum,
  IsNotEmpty,
  IsOptional,
  IsString,
  MaxLength,
  MinLength
} from 'class-validator'

export class CreateUserWithEmailPasswordDto {
  @IsString()
  @IsNotEmpty()
  @MinLength(3)
  @MaxLength(60)
  @ApiProperty()
  email: string

  @IsString()
  @IsNotEmpty()
  @ApiProperty()
  password: string

  @IsString()
  @IsNotEmpty()
  @MinLength(3)
  @MaxLength(40)
  @ApiProperty()
  displayName: string

  @ApiProperty()
  @IsBoolean()
  @IsNotEmpty({
    message:
      'You must agree to the Terms of Service and Privacy Policy to create an account: https://www.themirror.space/terms, https://www.themirror.space/privacy'
  })
  termsAgreedtoGeneralTOSandPP: boolean
}

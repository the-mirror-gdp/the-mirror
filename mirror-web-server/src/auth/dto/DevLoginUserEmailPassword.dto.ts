import { IsNotEmpty, IsString } from 'class-validator'

export class DevLoginUserEmailPassword {
  @IsString()
  @IsNotEmpty()
  // Don't include @ApiProperty() since this is a hidden, non-prod route
  email: string
  @IsString()
  @IsNotEmpty()
  // Don't include @ApiProperty() since this is a hidden, non-prod route
  password: string
}

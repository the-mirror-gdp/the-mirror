import { ApiProperty } from '@nestjs/swagger'
import {
  IsEnum,
  IsMongoId,
  IsNotEmpty,
  IsString,
  MaxLength
} from 'class-validator'
import { ROLE } from '../models/role.enum'

export class SetUserRoleForOneDto {
  @IsNotEmpty()
  @IsMongoId()
  @ApiProperty({
    description: 'The userId to set a role for'
  })
  targetUserId: string

  @IsNotEmpty()
  @IsEnum(ROLE)
  @ApiProperty({
    description: 'The ROLE number to set',
    enum: () => ROLE
  })
  role: ROLE
}

export class RemoveUserRoleForOneDto {
  @IsNotEmpty()
  @IsString()
  @MaxLength(24) // Mongo ID is 24
  @ApiProperty({
    description: 'The userId to unset a role for'
  })
  targetUserId: string
}

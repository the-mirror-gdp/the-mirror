import {
  IsEnum,
  IsNotEmpty,
  IsObject,
  IsOptional,
  IsString
} from 'class-validator'
import { ROLE } from '../models/role.enum'

// note: Don't use @ApiProperty() here because Roles isn't exposed via a controller
export class CreateRoleDto {
  @IsNotEmpty()
  @IsEnum(ROLE)
  defaultRole: ROLE

  @IsNotEmpty()
  @IsString()
  creator: string

  @IsOptional()
  @IsObject()
  users?: any

  @IsOptional()
  @IsObject()
  userGroups?: any
}

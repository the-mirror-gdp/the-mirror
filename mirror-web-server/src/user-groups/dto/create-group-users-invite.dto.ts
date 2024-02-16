import { ApiProperty } from '@nestjs/swagger'
import { IsBoolean, IsDate, IsNotEmpty, IsString } from 'class-validator'
import { USER_GROUP_INVITE_STATUSES } from '../../option-sets/user-group-invite-statuses'

export class CreateUserGroupInviteDto {
  /**
   * Required properties
   */
  @IsNotEmpty()
  @IsString()
  @ApiProperty()
  group: string

  @IsNotEmpty()
  @IsBoolean()
  @ApiProperty()
  unlimited: boolean

  @IsNotEmpty()
  @IsBoolean()
  @ApiProperty()
  used: boolean
  status: USER_GROUP_INVITE_STATUSES

  @IsNotEmpty()
  @IsBoolean()
  @ApiProperty()
  completed: boolean

  @IsNotEmpty()
  @IsString()
  @ApiProperty()
  creator: string // TODO userId?

  @IsNotEmpty()
  @IsString()
  @ApiProperty()
  recipient: string // TODO userId?

  @IsNotEmpty()
  @IsDate()
  @ApiProperty()
  expirationDate: Date
}

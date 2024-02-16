import { PartialType } from '@nestjs/swagger'
import { IsNotEmpty } from 'class-validator'
import { CreateUserGroupDto } from './create-group.users.dto'

export class UpdateUserGroupDto extends PartialType(CreateUserGroupDto) {}

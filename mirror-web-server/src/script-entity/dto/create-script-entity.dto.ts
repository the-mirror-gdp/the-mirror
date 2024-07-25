import { ApiProperty } from '@nestjs/swagger'
import { IsArray, IsEnum, IsNotEmpty, IsOptional } from 'class-validator'
import { ROLE } from '../../roles/models/role.enum'
export class CreateScriptEntityDto {
  @IsNotEmpty()
  @IsArray()
  @ApiProperty()
  blocks: any[] // 2023-07-24 15:18:04 changed from `scripts` to `blocks` to match the Godot client

  @IsOptional()
  @IsEnum(ROLE)
  @ApiProperty({
    example: 'The default role permission ',
    enum: ROLE,
    required: false
  })
  defaultRole?: ROLE
}

import { ApiProperty } from '@nestjs/swagger'
import { IsArray, IsNotEmpty } from 'class-validator'
export class CreateScriptEntityDto {
  @IsNotEmpty()
  @IsArray()
  @ApiProperty()
  blocks: any[] // 2023-07-24 15:18:04 changed from `scripts` to `blocks` to match the Godot client
}

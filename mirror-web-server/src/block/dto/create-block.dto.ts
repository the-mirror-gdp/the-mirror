import { ApiProperty } from '@nestjs/swagger'
import {
  IsBoolean,
  IsEnum,
  IsNotEmpty,
  IsOptional,
  IsString,
  MaxLength
} from 'class-validator'
import { BLOCK_TYPE } from '../../option-sets/block-type'
export class CreateBlockDto {
  /**
   * Required properties
   */
  @IsNotEmpty()
  @IsString()
  @ApiProperty()
  name: string

  @IsNotEmpty()
  @IsEnum(BLOCK_TYPE)
  @ApiProperty()
  blockType: string

  /**
   * Optional Properties
   */
  @IsOptional()
  @MaxLength(1000) // abitrary max length; must line up with schema definition
  @ApiProperty({
    example: "The Game Logic Block's Description"
  })
  description?: string

  @IsOptional()
  @IsBoolean()
  @ApiProperty()
  mirrorPublicLibrary?: boolean
}

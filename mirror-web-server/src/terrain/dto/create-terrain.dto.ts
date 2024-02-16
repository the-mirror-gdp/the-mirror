import { ApiProperty } from '@nestjs/swagger'
import {
  IsEnum,
  IsNotEmpty,
  IsOptional,
  IsString,
  IsNumber,
  MaxLength,
  IsBoolean
} from 'class-validator'
import { NOISE_TYPE } from '../../option-sets/noise-type'
import { TERRAIN_MATERIAL } from '../../option-sets/terrain-materials'
import { TERRAIN_GENERATOR } from '../../option-sets/terrain-generator'

export class CreateTerrainDto {
  @IsNotEmpty()
  @IsString()
  @MaxLength(300) // abitrary max length
  @ApiProperty({
    example: 'Mirror Terrain'
  })
  name: string

  @IsOptional()
  @IsEnum(TERRAIN_MATERIAL)
  @ApiProperty()
  material?: string

  @IsOptional()
  @IsString()
  @MaxLength(5000) // abitrary max length
  @ApiProperty({
    example: 'Mirror Terrain Description'
  })
  description?: string

  @IsOptional()
  @IsBoolean()
  @ApiProperty()
  public?: boolean

  @IsOptional()
  @IsEnum(TERRAIN_GENERATOR)
  @ApiProperty({ enum: TERRAIN_GENERATOR })
  generator?: string

  @IsOptional()
  @IsEnum(NOISE_TYPE)
  @ApiProperty()
  noiseType?: number

  @IsOptional()
  @IsNumber()
  @ApiProperty()
  positionX?: number

  @IsOptional()
  @IsNumber()
  @ApiProperty()
  positionY?: number

  @IsOptional()
  @IsNumber()
  @ApiProperty()
  positionZ?: number

  @IsOptional()
  @IsNumber()
  @ApiProperty()
  heightStart?: number

  @IsOptional()
  @IsNumber()
  @ApiProperty()
  heightRange?: number

  @IsOptional()
  @IsNumber()
  @ApiProperty()
  seed?: number
}

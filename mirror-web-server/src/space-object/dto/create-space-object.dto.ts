import { ApiProperty } from '@nestjs/swagger'
import {
  IsArray,
  IsBoolean,
  IsMongoId,
  IsNotEmpty,
  IsNumber,
  IsOptional,
  IsString,
  MaxLength,
  MinLength
} from 'class-validator'
import { Vector3AsArray, Vector4AsArray } from '../../option-sets/vectors'
import { AssetId } from '../../util/mongo-object-id-helpers'

export class CreateSpaceObjectDto {
  /**
   * Required properties
   */
  @IsNotEmpty()
  @IsString()
  @MinLength(24, {
    message: 'A Mongo ObjectId is 24 characters'
  })
  @MaxLength(24, {
    message: 'A Mongo ObjectId is 24 characters'
  })
  @ApiProperty({
    required: true
  })
  spaceId: string

  @IsNotEmpty()
  @IsString()
  @MaxLength(300) // abitrary max length
  @ApiProperty({
    example: 'A Cool Space Object'
  })
  name: string

  @IsNotEmpty()
  @IsMongoId()
  @ApiProperty()
  asset: AssetId // TODO make this clear that it's an assetId

  /**
   * Optional properties
   */
  @IsOptional()
  @IsString()
  @ApiProperty()
  parentSpaceObject?: string

  @IsOptional()
  @IsString()
  @ApiProperty({
    example: "A Cool Space Object's Description"
  })
  description?: string

  @IsOptional()
  @ApiProperty()
  locked?: boolean

  @IsOptional()
  @ApiProperty()
  preloadBeforeSpaceStarts?: boolean

  // Transform properties.
  @IsOptional()
  @ApiProperty()
  position?: Vector3AsArray

  @IsOptional()
  @ApiProperty()
  rotation?: Vector3AsArray

  @IsOptional()
  @ApiProperty()
  scale?: Vector3AsArray

  @IsOptional()
  @ApiProperty()
  offset?: Vector3AsArray

  // Physics properties.
  @IsOptional()
  @ApiProperty()
  collisionEnabled?: boolean

  @IsOptional()
  @IsString()
  @ApiProperty()
  shapeType?: string

  @IsOptional()
  @IsString()
  @ApiProperty()
  bodyType?: string

  // Deprecated but kept for compat, remove in the future.
  @IsOptional()
  @ApiProperty()
  staticEnabled?: boolean

  @IsOptional()
  @ApiProperty()
  massKg?: number

  @IsOptional()
  @ApiProperty()
  gravityScale?: number

  // Visibility properties
  @IsOptional()
  @IsBoolean()
  @ApiProperty()
  castShadows?: boolean

  @IsOptional()
  @IsNumber()
  @ApiProperty()
  visibleFrom?: number

  @IsOptional()
  @IsNumber()
  @ApiProperty()
  visibleTo?: number

  @IsOptional()
  @IsNumber()
  @ApiProperty()
  visibleFromMargin?: number

  @IsOptional()
  @IsNumber()
  @ApiProperty()
  visibleToMargin?: number

  // Material property. This references an Asset
  @IsOptional()
  @ApiProperty()
  materialAssetId?: string

  // Instance material properties. Defines the set of material parameters
  // that can be changed per individual SpaceObject instance
  @IsOptional()
  @ApiProperty()
  objectColor?: Vector4AsArray

  @IsOptional()
  @ApiProperty()
  objectTexture?: string

  /**
   * @deprecated
   * @description objectTextureSize was updated to Vector3. New property: objectTextureSizeV2. 2023-04-17
   */
  @IsOptional()
  @ApiProperty()
  objectTextureSize?: number

  @IsOptional()
  @ApiProperty()
  objectTextureSizeV2?: Vector3AsArray

  @IsOptional()
  @ApiProperty()
  objectTextureOffset?: Vector3AsArray

  @IsOptional()
  @ApiProperty()
  objectTextureTriplanar?: boolean

  @IsOptional()
  @ApiProperty()
  objectTextureRepeat?: boolean

  // Audio properties.
  @IsOptional()
  @ApiProperty()
  audioAutoPlay?: boolean

  @IsOptional()
  @ApiProperty()
  audioLoop?: boolean

  @IsOptional()
  @ApiProperty()
  audioIsSpatial?: boolean

  @IsOptional()
  @ApiProperty()
  audioPitch?: number

  @IsOptional()
  @ApiProperty()
  audioBaseVolume?: number

  @IsOptional()
  @ApiProperty()
  audioSpatialMaxVolume?: number

  @IsOptional()
  @ApiProperty()
  audioSpatialRange?: number

  @IsOptional()
  @IsArray()
  @ApiProperty()
  surfaceMaterialId?: any[]

  @IsOptional()
  @IsArray()
  @ApiProperty()
  scriptEvents?: any[]

  @IsOptional()
  @IsArray()
  @ApiProperty()
  extraNodes?: any[]
}

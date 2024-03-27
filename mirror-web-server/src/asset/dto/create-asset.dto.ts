import { ApiProperty } from '@nestjs/swagger'
import {
  IsArray,
  IsBoolean,
  IsNotEmpty,
  IsNumber,
  IsObject,
  IsOptional,
  IsString,
  MaxLength
} from 'class-validator'
import { ASSET_TYPE } from '../../option-sets/asset-type'
import { Vector4AsArray } from '../../option-sets/vectors'
import { ROLE } from '../../roles/models/role.enum'
import { Tags } from '../../tag/models/tags.schema'

export class CreateAssetDto {
  /**
   * Required properties
   */
  @IsNotEmpty()
  @IsString()
  @MaxLength(300) // abitrary max length
  @ApiProperty({
    example: 'An Awesome Asset',
    required: true
  })
  name: string

  @IsNotEmpty()
  @IsString()
  @ApiProperty({ enum: ASSET_TYPE })
  assetType: ASSET_TYPE

  /**
   * Optional Properties
   */
  @IsOptional()
  @ApiProperty({
    example: 'The default role permission for this Asset',
    enum: ROLE,
    required: false
  })
  defaultRole?: ROLE

  @IsOptional()
  @MaxLength(5000) // abitrary max length
  @ApiProperty({
    required: false,
    example: "The Awesome Asset's Description"
  })
  description?: string

  @IsOptional()
  @IsBoolean()
  @ApiProperty({ required: false })
  mirrorPublicLibrary?: boolean

  @IsOptional()
  @IsString()
  @ApiProperty({ required: false })
  customData?: string

  /**
   * START Section: Third Party Source for Mirror Public Library
   */
  @IsOptional()
  @IsString()
  @ApiProperty({
    required: false,
    example: 'CG Trader'
  })
  thirdPartySourceDisplayName?: string

  @IsOptional()
  @IsString()
  @ApiProperty({
    required: false,
    example: 'https://www.cgtrader.com/'
  })
  thirdPartySourceUrl?: string
  /**
   * END Section: Third Party Source for Mirror Public Library
   */

  @IsOptional()
  @IsString()
  @ApiProperty({
    required: false
  })
  thumbnail?: string

  /**
   * @deprecated use tagsV2 instead (separate collection)
   */
  @IsOptional()
  @IsString({ each: true })
  @ApiProperty({ required: false })
  categories?: string[]

  @IsOptional()
  @MaxLength(5000) // abitrary max length
  @ApiProperty({ required: false })
  currentFile?: string

  @IsOptional()
  @MaxLength(64)
  @ApiProperty({ required: false })
  fileHash?: string

  @IsOptional()
  @IsBoolean()
  @ApiProperty({ required: false })
  public?: boolean

  // Transform properties.
  @IsOptional()
  @IsNumber()
  @ApiProperty({ required: false })
  initPositionX?: number

  @IsOptional()
  @IsNumber()
  @ApiProperty({ required: false })
  initPositionY?: number

  @IsOptional()
  @IsNumber()
  @ApiProperty({ required: false })
  initPositionZ?: number

  @IsOptional()
  @IsNumber()
  @ApiProperty({ required: false })
  initRotationX?: number

  @IsOptional()
  @IsNumber()
  @ApiProperty({ required: false })
  initRotationY?: number

  @IsOptional()
  @IsNumber()
  @ApiProperty({ required: false })
  initRotationZ?: number

  @IsOptional()
  @IsNumber()
  @ApiProperty({ required: false })
  initScaleX?: number

  @IsOptional()
  @IsNumber()
  @ApiProperty({ required: false })
  initScaleY?: number

  @IsOptional()
  @IsNumber()
  @ApiProperty({ required: false })
  initScaleZ?: number

  // Physics properties.
  @IsOptional()
  @IsBoolean()
  @ApiProperty({ required: false })
  collisionEnabled?: boolean

  @IsOptional()
  @IsBoolean()
  @ApiProperty({ required: false })
  staticEnabled?: boolean

  @IsOptional()
  @IsNumber()
  @ApiProperty({ required: false })
  massKg?: number

  @IsOptional()
  @IsNumber()
  @ApiProperty({ required: false })
  gravityScale?: number

  // Material properties.
  @IsOptional()
  @ApiProperty({ required: false })
  objectColor?: Vector4AsArray

  @IsOptional()
  @ApiProperty({ required: false })
  tags?: Tags
}

// See https://www.loom.com/share/7e09d2777ef94368bcd5fd8c8341b5ef for walkthrough of DTOs with discriminators
export class CreateMaterialDto extends CreateAssetDto {
  @IsOptional()
  @IsString()
  @ApiProperty({ required: false })
  materialName?: string

  @IsOptional()
  @IsString()
  @ApiProperty({ required: false })
  materialTransparencyMode?: string

  @IsOptional()
  @IsString()
  @ApiProperty({ required: false })
  materialTransparencyProperties?: string

  @IsOptional()
  @IsArray()
  @ApiProperty({
    required: false,
    description: 'Array of ObjectIDs of Textures (Assets)'
  })
  textures?: string

  @IsOptional()
  @IsObject()
  @ApiProperty()
  parameters: any

  @IsOptional()
  @IsArray()
  @ApiProperty({
    required: false,
    description: 'Array of ObjectIDs of Textures (Assets)'
  })
  externalAssetIds?: string

  @IsOptional()
  @IsString()
  @ApiProperty()
  materialType: string

  @IsOptional()
  @IsString()
  @ApiProperty({ required: false })
  code?: string
}

export class CreateTextureDto extends CreateAssetDto {
  @IsOptional()
  @IsString()
  @ApiProperty({ required: false })
  textureImageFileHashMD5?: string

  @IsOptional()
  @IsString()
  @ApiProperty({ required: false })
  textureLowQualityFileHashMD5?: string

  @IsOptional()
  @IsString()
  @ApiProperty({ required: false })
  textureImagePropertyAppliesTo?: string
}

export class CreateMapDto extends CreateAssetDto {
  @IsOptional()
  @IsString()
  @ApiProperty({ required: false })
  mapName?: string

  // Heightmap Image property. This references an Asset
  @IsOptional()
  @ApiProperty({ required: false })
  heightmapAssetId?: string

  // Material property. This references an Asset
  @IsOptional()
  @ApiProperty({ required: false })
  flatMaterialAssetId?: string

  // Material property. This references an Asset
  @IsOptional()
  @ApiProperty({ required: false })
  cliffMaterialAssetId?: string

  @IsOptional()
  @IsNumber()
  @ApiProperty({ required: false })
  mapSize?: number

  @IsOptional()
  @IsNumber()
  @ApiProperty({ required: false })
  mapPrecision?: number

  @IsOptional()
  @IsNumber()
  @ApiProperty({ required: false })
  heightScale?: number

  @IsOptional()
  @IsNumber()
  @ApiProperty({ required: false })
  layerOffset?: number

  @IsOptional()
  @IsNumber()
  @ApiProperty({ required: false })
  flatUVScale?: number

  @IsOptional()
  @IsNumber()
  @ApiProperty({ required: false })
  cliffUVScale?: number

  @IsOptional()
  @IsNumber()
  @ApiProperty({ required: false })
  flatCliffRatio?: number

  @IsOptional()
  @IsArray()
  @IsNumber({}, { each: true })
  @ApiProperty({ required: false })
  flatColor?: Vector4AsArray

  @IsOptional()
  @IsArray()
  @IsNumber({}, { each: true })
  @ApiProperty({ required: false })
  cliffColor?: Vector4AsArray

  @IsOptional()
  @ApiProperty({ required: false })
  colormapAssetId?: string

  @IsOptional()
  @ApiProperty({ required: false })
  colormapStrength?: number
}

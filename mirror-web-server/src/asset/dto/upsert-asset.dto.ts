import {
  IsBoolean,
  IsEnum,
  IsNotEmpty,
  IsNumber,
  IsString
} from 'class-validator'
import { ASSET_TYPE } from '../../option-sets/asset-type'
import { Vector4AsArray } from '../../option-sets/vectors'

export class UpsertAssetDto {
  @IsNotEmpty()
  @IsString()
  name: string
  @IsNotEmpty()
  @IsEnum(ASSET_TYPE)
  assetType: ASSET_TYPE
  @IsNotEmpty()
  @IsString()
  description: string
  @IsNotEmpty()
  @IsString()
  owner: string
  @IsNotEmpty()
  @IsNumber()
  initPositionX: number
  @IsNotEmpty()
  @IsNumber()
  initPositionY: number
  @IsNotEmpty()
  @IsNumber()
  initPositionZ: number
  @IsNotEmpty()
  @IsNumber()
  initRotationX: number
  @IsNotEmpty()
  @IsNumber()
  initRotationY: number
  @IsNotEmpty()
  @IsNumber()
  initRotationZ: number
  @IsNotEmpty()
  @IsNumber()
  initScaleX: number
  @IsNotEmpty()
  @IsNumber()
  initScaleY: number
  @IsNotEmpty()
  @IsNumber()
  initScaleZ: number
  @IsNotEmpty()
  @IsBoolean()
  collisionEnabled: boolean
  @IsNotEmpty()
  @IsBoolean()
  staticEnabled: boolean
  @IsNotEmpty()
  @IsNumber()
  massKg: number
  @IsNotEmpty()
  @IsNumber()
  gravityScale: number
  @IsNotEmpty()
  objectColor: Vector4AsArray
}

import { ApiProperty } from '@nestjs/swagger'
import { Transform } from 'class-transformer'
import { IsOptional, IsString, IsEnum, IsArray } from 'class-validator'
import { ASSET_TYPE } from 'src/option-sets/asset-type'
import { SORT_DIRECTION } from 'src/util/pagination/pagination.interface'
import { PaginatedSearchAssetDto } from './paginated-search-asset.dto'

/**
 * @deprecated 2023-03-01 13:24:23 I believe PaginatedSearchAssetDto should be used instead
 */
export class GetAssetDto extends PaginatedSearchAssetDto {
  @IsOptional()
  @IsString()
  @ApiProperty({
    required: false
  })
  startItem: number

  @IsOptional()
  @IsString()
  @ApiProperty({ required: false })
  numberOfItems: number
}

export class AssetParamsDto {
  @IsOptional()
  @IsString()
  @ApiProperty({
    required: false
  })
  startItem: number

  @IsOptional()
  @IsString()
  @ApiProperty({ required: false })
  numberOfItems: number
}

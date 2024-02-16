import { SORT_DIRECTION } from './../../util/pagination/pagination.interface'
import { ApiProperty } from '@nestjs/swagger'
import { Transform } from 'class-transformer'
import {
  IsOptional,
  IsString,
  IsEnum,
  IsArray,
  ValidateIf,
  IsNotEmpty
} from 'class-validator'
import { ASSET_TYPE } from '../../option-sets/asset-type'
import { PopulateField } from '../../util/pagination/pagination.service'
import { IsSortDirection } from '../../util/validators/sort-directions.validator'
import { TAG_TYPES } from '../../tag/models/tag-types.enum'
import { ApiArrayQuery } from '../../util/decorators/api-array-query.decorator'

export class PaginatedSearchAssetDto {
  @IsOptional()
  @IsString()
  @ApiProperty()
  field: string

  @IsOptional()
  @IsString()
  @ApiProperty()
  search: string

  @IsOptional()
  @IsString()
  @ApiProperty({
    description: `Default is updatedAt: desc`
  })
  sortKey: string

  @IsOptional()
  @ApiProperty({
    description: `Default is updatedAt: desc`
  })
  @IsSortDirection()
  sortDirection: SORT_DIRECTION

  @IsOptional()
  @ApiProperty()
  page: number

  @IsOptional()
  @ApiProperty()
  perPage: number

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

  /**
   * @deprecated use assetType instead to line up with MongoDB property. This will be overriden by assetType if both are provided
   */
  @IsOptional()
  @IsString()
  @ApiProperty({
    description:
      'DEPRECATED: use assetType instead to line up with MongoDB property. This will be overriden by assetType if both are provided'
  })
  type: ASSET_TYPE

  /**
   * @deprecated use assetTypes (plural), below
   */
  @IsOptional()
  @IsEnum(ASSET_TYPE, {
    message: `assetType must be one of: ${Object.values(ASSET_TYPE).join(
      ', '
    )} (case sensitive)`
  })
  @ApiProperty({
    enum: ASSET_TYPE,
    description: `
    Filter by assetType. Options: ${Object.values(ASSET_TYPE).join(', ')}.
      `
  })
  assetType: ASSET_TYPE

  @IsOptional()
  @IsArray()
  @Transform(({ value }) => value?.toString().split(',').map(String)) // This transforms the comma-separated strings into an array of strings
  @IsEnum(ASSET_TYPE, {
    message: `assetTypes must be one of: ${Object.values(ASSET_TYPE).join(
      ', '
    )} (case sensitive)`,
    each: true
  })
  @ApiProperty({
    enum: ASSET_TYPE,
    description: `
    Filter by assetType as array. Options: ${Object.values(ASSET_TYPE).join(
      ', '
    )}.
      `
  })
  assetTypes: ASSET_TYPE[]

  @IsOptional()
  @ApiArrayQuery([String])
  @Transform(({ value }) => (Array.isArray(value) ? value : [value]))
  tag?: string[]

  @ValidateIf((o) => o.tag)
  @IsNotEmpty()
  @IsEnum(TAG_TYPES)
  @ApiProperty({ enum: () => TAG_TYPES })
  tagType?: TAG_TYPES
}

/**
 * @description This adds the populate property
 * @date 2023-07-20 07:57
 */
export class PaginatedSearchAssetDtoV2 extends PaginatedSearchAssetDto {
  @IsOptional()
  @IsArray()
  @Transform(({ value }) => value?.toString().split(',').map(String)) // This transforms the comma-separated strings into an array of strings
  @ApiProperty({
    description: 'Comma-separated list of fields to populate',
    examples: ['creator', 'owner', 'tagsV2', 'creator']
  })
  populate: string[]

  @IsOptional()
  @ApiProperty({ required: false })
  @Transform(({ value }) => value === 'true' || value === true)
  includeSoftDeleted?: boolean
}

export function getPopulateFieldsFromPaginatedSearchAssetDto(searchAssetDto) {
  const populateFields: PopulateField[] = []

  searchAssetDto?.populate?.includes('creator') &&
    populateFields.push({
      localField: 'creator', // TODO: filter out properties for user so that not all are passed back
      from: 'users',
      unwind: true,
      // use this to filter properties
      project: {
        displayName: 1
      }
    })
  searchAssetDto?.populate?.includes('owner') &&
    populateFields.push({
      localField: 'owner',
      from: 'users',
      unwind: true,
      // use this to filter properties
      project: {
        displayName: 1
      }
    })
  searchAssetDto?.populate?.includes('customData') &&
    populateFields.push({
      localField: 'customData',
      from: 'customdatas',
      unwind: true
    })
  return populateFields
}

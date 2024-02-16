import { ApiProperty } from '@nestjs/swagger'
import { Transform } from 'class-transformer'
import { IsOptional, IsString } from 'class-validator'
import { SORT_DIRECTION } from '../../util/pagination/pagination.interface'

/**
 * @description Basing this off of PaginatedSearchSpaceDto as boilerplate
 * @date 2023-04-25 02:37:37
 */
export class PaginatedSearchZoneDto {
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
  // @IsString()
  @ApiProperty({
    description: `Default is updatedAt: desc`
  })
  @Transform(({ value }) => {
    // careful here: this is getting called multiples for some reason, so we need to check for numerical values too
    if (
      value?.toString()?.toLowerCase() === 'asc' ||
      value === 1 ||
      value === '1'
    ) {
      return SORT_DIRECTION.ASC
    }
    if (
      value?.toString()?.toLowerCase() === 'desc' ||
      value === -1 ||
      value === '-1'
    ) {
      return SORT_DIRECTION.DESC
    }
  })
  sortDirection: SORT_DIRECTION

  @IsOptional()
  @ApiProperty()
  page: number

  @IsOptional()
  @ApiProperty()
  perPage: number
}

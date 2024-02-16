import { ApiProperty } from '@nestjs/swagger'
import { IsOptional, IsString } from 'class-validator'

/**
 * @deprecated 2023-03-01 13:24:23 I believe PaginatedSearchAssetDto should be used instead
 */
export class SearchAssetDto {
  @IsOptional()
  @IsString()
  @ApiProperty({
    required: false
  })
  field: string

  @IsOptional()
  @IsString()
  @ApiProperty({ required: false })
  search: string
}

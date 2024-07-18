import { ApiProperty } from '@nestjs/swagger'
import { IsArray } from 'class-validator'
import { AssetId } from '../../util/mongo-object-id-helpers'

export class GetAssetsPriceDto {
  @IsArray()
  @ApiProperty()
  assetsIds: AssetId[]
}

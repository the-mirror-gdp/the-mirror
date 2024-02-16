import { IsOptional, IsString } from 'class-validator'
import { ApiProperty, PartialType } from '@nestjs/swagger'
import { CreateAssetDto } from './create-asset.dto'
import { AssetDiscriminators } from '../asset.schema'
import { PurchaseOption } from '../../marketplace/purchase-option.subdocument.schema'

export class UpdateAssetDto extends PartialType(CreateAssetDto) {
  /**
   * @description If a discriminator/subclassed Asset is being updated, then this must be included. Otherwise, the parent Asset will be used, but because Mongoose is NOT typed under the hood, it won't know about the discriminator classes and thus won't work with properties of the discriminator if the discriminator model isn't used.
   * @date 2023-06-07 11:24
   */
  @IsOptional()
  @IsString()
  @ApiProperty({
    required: false
  })
  __t?: AssetDiscriminators
}

export class AddAssetPurchaseOptionDto extends PurchaseOption {}

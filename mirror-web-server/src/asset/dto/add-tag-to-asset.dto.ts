import {
  IsEnum,
  IsMongoId,
  IsNotEmpty,
  IsString,
  IsUrl,
  ValidateIf
} from 'class-validator'
import { ApiProperty } from '@nestjs/swagger'
import { TAG_TYPES } from '../../tag/models/tag-types.enum'
import { AssetId } from '../../util/mongo-object-id-helpers'

export class AddTagToAssetDto {
  @IsNotEmpty()
  @IsMongoId()
  @ApiProperty()
  assetId: AssetId

  @IsNotEmpty()
  @IsString()
  @ApiProperty()
  tagName: string

  @IsNotEmpty()
  @IsEnum(TAG_TYPES)
  @ApiProperty({ enum: () => TAG_TYPES })
  tagType: TAG_TYPES

  @ValidateIf((o) => o.tagType === TAG_TYPES.THIRD_PARTY)
  @IsNotEmpty()
  @IsUrl()
  @ApiProperty()
  thirdPartySourceHomePageUrl: string
}

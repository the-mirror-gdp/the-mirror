import {
  IsEnum,
  IsMongoId,
  IsNotEmpty,
  IsOptional,
  IsString,
  IsUrl,
  ValidateIf
} from 'class-validator'
import { SpaceId } from '../../util/mongo-object-id-helpers'
import { ApiProperty } from '@nestjs/swagger'
import { TAG_TYPES } from '../../tag/models/tag-types.enum'

export class AddTagToSpaceDto {
  @IsNotEmpty()
  @IsMongoId()
  @ApiProperty()
  spaceId: SpaceId

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

import {
  IsEnum,
  IsMongoId,
  IsNotEmpty,
  IsString,
  IsUrl,
  ValidateIf
} from 'class-validator'
import { SpaceObjectId } from '../../util/mongo-object-id-helpers'
import { ApiProperty } from '@nestjs/swagger'
import { TAG_TYPES } from '../../tag/models/tag-types.enum'

export class AddTagToSpaceObjectDto {
  @IsNotEmpty()
  @IsMongoId()
  @ApiProperty()
  spaceObjectId: SpaceObjectId

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

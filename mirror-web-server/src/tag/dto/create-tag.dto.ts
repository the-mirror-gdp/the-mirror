import { ApiProperty } from '@nestjs/swagger'
import {
  IsBoolean,
  IsEnum,
  IsNotEmpty,
  IsOptional,
  IsString
} from 'class-validator'
import { TAG_TYPE } from '../../option-sets/tag-type'
export class CreateTagDto {
  @IsNotEmpty()
  @IsString()
  @ApiProperty()
  name: string

  /**
   * Optional
   */
  @IsOptional()
  @IsEnum(TAG_TYPE)
  @ApiProperty({
    enum: Object.values(TAG_TYPE),
    description: `.Specifies the discriminator/subclass of the tag. Optional: defaults to USER_GENERATED. Options: ${Object.values(
      TAG_TYPE
    ).join(', ')}'}`
  })
  tagType: TAG_TYPE

  @IsOptional()
  @IsBoolean()
  @ApiProperty()
  mirrorPublicLibrary: boolean

  @IsOptional()
  @IsBoolean()
  @ApiProperty()
  public: boolean

  @IsOptional()
  @IsString()
  @ApiProperty()
  parentTag: string
}

export class CreateThirdPartySourceTagDto extends CreateTagDto {
  @IsNotEmpty()
  @IsString()
  @ApiProperty()
  thirdPartySourceHomePageUrl: string

  /**
   * Optional
   */
  @IsOptional()
  @IsString()
  @ApiProperty()
  thirdPartySourcePublicDescription: string

  @IsOptional()
  @IsString()
  @ApiProperty()
  thirdPartySourceTwitterUrl: string

  @IsOptional()
  @IsString()
  @ApiProperty()
  thirdPartySourceTMUserId: string
}

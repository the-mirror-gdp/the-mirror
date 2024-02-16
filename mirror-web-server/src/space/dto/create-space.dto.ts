import { ApiProperty } from '@nestjs/swagger'
import {
  IsArray,
  IsEnum,
  IsNotEmpty,
  IsOptional,
  IsString,
  IsNumber,
  MaxLength,
  ArrayMaxSize,
  IsObject
} from 'class-validator'
import { SPACE_TYPE } from '../../option-sets/space'
import { SPACE_TEMPLATE } from '../../option-sets/space-templates'
import { BUILD_PERMISSIONS } from '../../option-sets/build-permissions'
import { Tags } from '../../tag/models/tags.schema'

// Don't include `owner` here because we'll want to put that on a separate route for safety with additional checks, e.g. the logic to handle transfer of a group-owned space will have additional steps
export class CreateSpaceDto {
  @IsNotEmpty()
  @IsString()
  @MaxLength(300) // arbitrary max length
  @ApiProperty({
    example: 'An Epic Space'
  })
  name: string

  /**
   * Optional properties
   */
  @IsOptional()
  @IsEnum(SPACE_TYPE)
  @ApiProperty()
  type: string

  /**
   * START Section: Roles
   */
  @IsOptional()
  @IsObject()
  @ApiProperty()
  users?: object

  @IsOptional()
  @IsObject()
  @ApiProperty()
  userGroups?: object
  /**
   * END Section: Roles
   */

  @IsOptional()
  @IsString()
  @ApiProperty()
  terrain?: string // Terrain Object Id

  @IsOptional()
  @IsString()
  @ApiProperty()
  environment?: string // Environment Object Id

  @IsOptional()
  @IsString()
  @ApiProperty()
  ownerUserGroup?: string // UserGroup Object Id

  /**
   * @deprecated use fromTemplate instead
   * @date 2023-07-20 16:15
   */
  @IsOptional()
  @IsEnum(SPACE_TEMPLATE)
  @ApiProperty({
    deprecated: true,
    description:
      'Deprecated; use fromTemplate: spaceId instead and use the duplicate Space route'
  })
  template: string

  @IsOptional()
  @IsNumber()
  @ApiProperty()
  lowerLimitY?: number

  @IsOptional()
  @IsString()
  @MaxLength(5000) // arbitrary max length
  @ApiProperty({
    example: "An Epic Space's Description"
  })
  description?: string

  @IsOptional()
  @IsString({ each: true })
  @ApiProperty()
  images?: string[]

  @IsOptional()
  @ApiProperty({ enum: () => BUILD_PERMISSIONS, required: false })
  @IsEnum(BUILD_PERMISSIONS)
  publicBuildPermissions?: BUILD_PERMISSIONS

  @IsOptional()
  @ApiProperty()
  tags?: Tags

  @IsOptional()
  @IsNumber()
  @ApiProperty({ required: false })
  maxUsers?: number
}

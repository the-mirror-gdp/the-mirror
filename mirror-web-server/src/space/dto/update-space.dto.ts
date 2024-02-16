import { ApiProperty, PartialType } from '@nestjs/swagger'
import {
  IsArray,
  IsObject,
  IsOptional,
  IsString,
  IsBoolean,
  MaxLength,
  ArrayMaxSize,
  IsEnum,
  IsNumber
} from 'class-validator'
import { ICustomDataKeyValuePairUpdateDto } from '../../custom-data/dto/custom-data.dto'
import { CustomDataId } from '../../util/mongo-object-id-helpers'
import { CreateSpaceDto } from './create-space.dto'
import { BUILD_PERMISSIONS } from '../../option-sets/build-permissions'

// Don't include `owner` here because we'll want to put that on a separate route for safety with additional checks, e.g. the logic to handle transfer of a group-owned space will have additional steps
export class UpdateSpaceDto
  extends PartialType(CreateSpaceDto)
  implements ICustomDataKeyValuePairUpdateDto
{
  /**
   * @description These properties are PATCHED onto custom data (overwrites declared key-value pairs, but doesn't affect other key/value parirs)
   * @date 2023-04-05 23:27
   */
  @IsOptional()
  @IsObject()
  @ApiProperty()
  patchCustomData?: object

  @IsOptional()
  @IsString()
  @ApiProperty()
  activeSpaceVersion?: string
  /**
   * @description These properties are deleted from custom data. Other properties will not be affected
   * @date 2023-04-05 23:27
   */
  @IsOptional()
  @IsArray()
  @ApiProperty()
  removeCustomDataKeys?: CustomDataId[] // 2023-06-05 17:00:27 should this be string[]?

  /**
   * @description These properties are PATCHED onto spaceVariablesData (overwrites declared key-value pairs, but doesn't affect other key/value parirs)
   * @date 2023-06-05 16:59:22
   */
  @IsOptional()
  @IsObject()
  @ApiProperty()
  patchSpaceVariablesData?: object

  /**
   * @description These properties are deleted from spaceVariablesData. Other properties will not be affected
   * @date 2023-06-05 16:59:26
   */
  @IsOptional()
  @IsArray()
  @ApiProperty()
  removeSpaceVariablesDataKeys?: string[]

  @IsOptional()
  @IsString({ each: true })
  @ApiProperty()
  tagsV2?: string[]

  @IsOptional()
  @IsString({ each: true })
  @ApiProperty()
  scriptIds?: string[]

  @IsOptional()
  @IsArray()
  @ApiProperty()
  scriptInstances?: any[]

  @IsOptional()
  @IsArray()
  @ApiProperty()
  materialInstances?: any[]

  @IsOptional()
  @IsEnum(BUILD_PERMISSIONS)
  @ApiProperty({ enum: () => BUILD_PERMISSIONS })
  publicBuildPermissions: BUILD_PERMISSIONS

  @IsOptional()
  @IsArray()
  @ApiProperty()
  kickRequests: string[]
}

export class CreateNewSpaceVersionDto {
  @IsOptional()
  @IsBoolean()
  @ApiProperty()
  updateSpaceWithActiveSpaceVersion: boolean

  @IsOptional()
  @IsString()
  @ApiProperty()
  name: string
}

export class SpaceCopyFromTemplateDto {
  @IsOptional()
  @IsString()
  @ApiProperty()
  name: string

  @IsOptional()
  @IsString()
  @ApiProperty()
  description: string

  @IsOptional()
  @IsEnum(BUILD_PERMISSIONS)
  @ApiProperty({ enum: () => BUILD_PERMISSIONS })
  publicBuildPermissions: BUILD_PERMISSIONS

  @IsOptional()
  @IsNumber()
  @ApiProperty({ required: false })
  maxUsers?: number = 24
}

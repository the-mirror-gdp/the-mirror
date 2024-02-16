import { ApiProperty } from '@nestjs/swagger'
import {
  IsDate,
  IsEnum,
  IsMongoId,
  IsNotEmpty,
  IsNumber,
  IsOptional,
  IsString,
  MaxLength,
  MinLength,
  ValidateIf
} from 'class-validator'
import { CONTAINER_STATE } from '../space-manager-external.service'
import { ZONE_MODE } from '../zone.schema'

export class CreateZoneDto {
  @IsNotEmpty()
  @IsEnum(ZONE_MODE)
  @MaxLength(100)
  @ApiProperty({
    example: 'Zone'
  })
  zoneMode: string

  /**
   * @description The UserId of the user who created the zone. It's optional, but we do want this. It's just set to optional for other CreateZoneDto's validation on the cron job.
   * @date 2023-06-17 22:42
   */
  @IsOptional()
  @IsMongoId()
  @MinLength(24, {
    message: 'A Mongo ObjectId is 24 characters'
  })
  @MaxLength(24, {
    message: 'A Mongo ObjectId is 24 characters'
  })
  @ApiProperty()
  owner?: string

  @IsNotEmpty()
  @IsEnum(CONTAINER_STATE)
  @MaxLength(100)
  @ApiProperty()
  state: string

  @IsNotEmpty()
  @IsString()
  @MaxLength(100)
  @ApiProperty()
  ipAddress: string

  @IsNotEmpty()
  @IsNumber()
  @ApiProperty()
  port: number

  @IsNotEmpty()
  @IsString()
  @MaxLength(100)
  @ApiProperty()
  uuid: string

  @IsNotEmpty()
  @IsString()
  @MaxLength(100)
  @ApiProperty()
  url: string

  @IsNotEmpty()
  @IsString()
  @MaxLength(50)
  @ApiProperty()
  gdServerVersion: string

  @IsOptional()
  @IsDate()
  @ApiProperty()
  containerLastRefreshed?: Date

  @IsOptional()
  @IsString()
  @MaxLength(300)
  @ApiProperty({
    example: 'Zone'
  })
  name?: string

  @IsOptional()
  @IsString()
  @ApiProperty({
    example: 'My New Zone'
  })
  description?: string

  /**
   * Only required if Build mode, but still run validation in case it exists for some reason (such as manual zone/server creation on the scaler without validation via mirror-server)
   */
  @IsOptional()
  @IsMongoId()
  @MinLength(24, {
    message: 'A Mongo ObjectId is 24 characters'
  })
  @MaxLength(24, {
    message: 'A Mongo ObjectId is 24 characters'
  })
  @ApiProperty()
  space?: string

  /**
   * Only required if Play mode, but still run validation in case it exists for some reason(such as manual zone/server creation on the scaler without validation via mirror-server)
   */
  @IsOptional()
  @IsMongoId()
  @MinLength(24, {
    message: 'A Mongo ObjectId is 24 characters'
  })
  @MaxLength(24, {
    message: 'A Mongo ObjectId is 24 characters'
  })
  @ApiProperty()
  spaceVersion?: string
}

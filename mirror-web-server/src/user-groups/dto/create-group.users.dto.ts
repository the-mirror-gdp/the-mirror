import { ApiProperty } from '@nestjs/swagger'
import { IsBoolean, IsNotEmpty, IsOptional, IsString } from 'class-validator'

export class CreateUserGroupDto {
  /**
   * Required properties
   */
  @IsNotEmpty()
  @IsString()
  @ApiProperty()
  name: string

  @IsNotEmpty()
  @IsBoolean()
  @ApiProperty()
  public: boolean

  /**
   * Optional properties
   */

  @IsOptional()
  @IsString()
  @ApiProperty()
  publicDescription: string

  @IsOptional()
  @IsString()
  @ApiProperty()
  primaryContact: string // TODO is this a userId?

  @IsOptional()
  @IsString({ each: true })
  @ApiProperty()
  moderators: string[]

  @IsOptional()
  @IsString({ each: true })
  @ApiProperty()
  owners: string[]

  @IsOptional()
  @IsString()
  @ApiProperty()
  image: string // url. TODO make this more clear

  @IsOptional()
  @IsString()
  @ApiProperty()
  discordUrl: string

  @IsOptional()
  @IsString()
  @ApiProperty()
  polygonDaoContractPublicKey: string

  @IsOptional()
  @IsString()
  @ApiProperty()
  ethereumDaoContractPublicKey: string

  @IsOptional()
  @IsString()
  @ApiProperty()
  twitterUrl: string

  @IsOptional()
  @IsString()
  @ApiProperty()
  websiteUrl: string

  @IsOptional()
  @IsString()
  @ApiProperty()
  creator: string // Temporarily add as optional until better handle by create request
}

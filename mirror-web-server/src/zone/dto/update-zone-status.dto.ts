import { ApiProperty } from '@nestjs/swagger'
import { IsOptional } from 'class-validator'

export class UpdateZoneStatusDto {
  @IsOptional()
  @ApiProperty()
  id?: string

  @IsOptional()
  @ApiProperty()
  uuid?: string

  @IsOptional()
  @ApiProperty()
  state?: string

  @IsOptional()
  @ApiProperty()
  url?: string

  @IsOptional()
  @ApiProperty()
  version?: string

  @IsOptional()
  @ApiProperty()
  address?: string

  @IsOptional()
  @ApiProperty()
  port?: number
}

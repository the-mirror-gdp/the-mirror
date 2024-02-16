import { ApiProperty } from '@nestjs/swagger'
import { Transform } from 'class-transformer'
import { IsOptional } from 'class-validator'

export class PopulateZoneOwnerDto {
  @IsOptional()
  @ApiProperty({ required: false })
  @Transform(({ value }) => value === 'true' || value === true)
  populateOwner?: boolean
}

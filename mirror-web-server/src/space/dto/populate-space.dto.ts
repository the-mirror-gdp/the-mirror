import { ApiProperty } from '@nestjs/swagger'
import { Transform } from 'class-transformer'
import { IsOptional } from 'class-validator'

export class PopulateSpaceDto {
  @IsOptional()
  @ApiProperty({ required: false })
  @Transform(({ value }) => value === 'true' || value === true)
  populateCreator?: boolean

  @IsOptional()
  @ApiProperty({ required: false })
  @Transform(({ value }) => value === 'true' || value === true)
  populateUsersPresent?: boolean
}

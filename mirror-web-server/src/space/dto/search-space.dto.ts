import { ApiProperty } from '@nestjs/swagger'
import { IsNotEmpty, IsString } from 'class-validator'
export class SearchSpaceDto {
  @IsNotEmpty()
  @IsString()
  @ApiProperty()
  searchField: string

  @IsNotEmpty()
  @IsString()
  @ApiProperty()
  searchString: string
}

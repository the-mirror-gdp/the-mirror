import { ApiProperty } from '@nestjs/swagger'
import { IsNotEmpty, IsString } from 'class-validator'
export class SearchUserGroupDto {
  @IsNotEmpty()
  @IsString()
  @ApiProperty()
  searchField: string

  @IsNotEmpty()
  @IsString()
  @ApiProperty()
  searchstring: string
}

import { ApiProperty } from '@nestjs/swagger'
import { IsNotEmpty, IsString } from 'class-validator'

export class AddUserSidebarTagDto {
  @IsNotEmpty()
  @IsString()
  @ApiProperty()
  sidebarTag: string
}

import { ApiProperty } from '@nestjs/swagger'
import { IsNotEmpty, IsString } from 'class-validator'

export class CreateFavoriteDto {
  @IsNotEmpty()
  @IsString()
  @ApiProperty()
  asset: string

  @IsNotEmpty()
  user: string // TODO should this be userId?

  // pass in the ObjectId of the owner (User) as a string
  @IsNotEmpty()
  creator: string // TODO creatorId?
}

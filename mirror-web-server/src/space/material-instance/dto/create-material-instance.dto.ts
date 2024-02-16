import { ApiProperty } from '@nestjs/swagger'
import { IsNotEmpty, IsObject, IsString } from 'class-validator'
import { SpaceId } from '../../../util/mongo-object-id-helpers'
export class CreateMaterialInstanceDto {
  @IsNotEmpty()
  @IsObject()
  @ApiProperty()
  parameters: any

  @IsNotEmpty()
  @IsString()
  @ApiProperty()
  spaceId: SpaceId
}

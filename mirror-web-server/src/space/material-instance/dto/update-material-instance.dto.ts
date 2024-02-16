import { ApiProperty, PartialType } from '@nestjs/swagger'
import { CreateMaterialInstanceDto } from './create-material-instance.dto'
import { IsNotEmpty, IsObject } from 'class-validator'

export class UpdateMaterialInstanceDto
  implements Omit<CreateMaterialInstanceDto, 'spaceId'>
{
  // we don't want to allow updating the spaceId here because that could allow for modifying someone else's space
  @IsNotEmpty()
  @IsObject()
  @ApiProperty()
  parameters: any
}

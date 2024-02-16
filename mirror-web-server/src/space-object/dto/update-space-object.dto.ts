import { PartialType } from '@nestjs/swagger'
import { CreateSpaceObjectDto } from './create-space-object.dto'

export class UpdateSpaceObjectDto extends PartialType(CreateSpaceObjectDto) {}

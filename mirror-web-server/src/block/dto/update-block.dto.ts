import { PartialType } from '@nestjs/swagger'
import { CreateBlockDto } from './create-block.dto'

export class UpdateBlockDto extends PartialType(CreateBlockDto) {}

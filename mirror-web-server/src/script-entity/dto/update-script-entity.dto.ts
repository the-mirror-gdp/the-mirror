import { PartialType } from '@nestjs/swagger'
import { CreateScriptEntityDto } from './create-script-entity.dto'

export class UpdateScriptEntityDto extends PartialType(CreateScriptEntityDto) {}

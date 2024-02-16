import { PartialType } from '@nestjs/swagger'
import { CreateTerrainDto } from './create-terrain.dto'

export class UpdateTerrainDto extends PartialType(CreateTerrainDto) {}

import { PartialType } from '@nestjs/swagger'
import { Environment } from '../environment.schema'

export class UpdateEnvironmentDto extends PartialType(Environment) {}

import { Environment } from './environment.schema'
import { ApiResponseProperty } from '@nestjs/swagger'

export class EnvironmentApiResponse extends Environment {
  @ApiResponseProperty()
  _id: string
}

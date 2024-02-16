import { ApiProperty } from '@nestjs/swagger'
import { ISpaceServer } from '../abstractions/space-server.interface'

export class SpaceStatsModel {
  @ApiProperty()
  AVG_RATING: number

  @ApiProperty()
  COUNT_LIKE: number

  @ApiProperty()
  COUNT_FOLLOW: number

  @ApiProperty()
  COUNT_SAVES: number

  @ApiProperty()
  COUNT_RATING: number

  @ApiProperty()
  usersCount: number

  @ApiProperty()
  servers: Record<string, ISpaceServer>

  @ApiProperty()
  usersPresent: string[]
}

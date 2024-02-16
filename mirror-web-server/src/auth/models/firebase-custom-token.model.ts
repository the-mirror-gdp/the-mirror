import { ApiProperty } from '@nestjs/swagger'

export class FirebaseCustomTokenResponse {
  @ApiProperty()
  token: string
}

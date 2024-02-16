import { ApiProperty } from '@nestjs/swagger'

export class DiscordUserInfo {
  @ApiProperty()
  id: string

  @ApiProperty()
  username: string

  @ApiProperty()
  avatar: string

  @ApiProperty()
  avatar_decoration: string

  @ApiProperty()
  discriminator: string

  @ApiProperty()
  public_flags: number

  @ApiProperty()
  flags: number

  @ApiProperty()
  banner: string

  @ApiProperty()
  banner_color: string

  @ApiProperty()
  accent_color: string

  @ApiProperty()
  locale: string

  @ApiProperty()
  mfa_enabled: boolean

  @ApiProperty()
  email: string

  @ApiProperty()
  verified: boolean
}

import { Controller, Post, Query } from '@nestjs/common'
import { FirebaseTokenAuthGuard } from '../auth/auth.guard'
import { LoginCodeService } from './login-code.service'

@Controller('login-code')
export class LoginCodeController {
  constructor(private readonly loginCodeService: LoginCodeService) {}

  @Post('generate-login-code')
  @FirebaseTokenAuthGuard()
  async createLoginCode(
    @Query('userId') userId: string,
    @Query('spaceId') spaceId: string,
    @Query('refreshToken') refreshToken: string
  ) {
    return await this.loginCodeService.createLoginCode(
      userId,
      spaceId,
      refreshToken
    )
  }

  @Post('check-login-code')
  async checkLoginCode(@Query('loginCode') loginCode: string) {
    return await this.loginCodeService.getLoginCodeRecordByLoginCode(loginCode)
  }
}

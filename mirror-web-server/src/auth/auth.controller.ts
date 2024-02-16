import {
  Body,
  Controller,
  Delete,
  Logger,
  Post,
  UsePipes,
  ValidationPipe
} from '@nestjs/common'
import { AuthService } from './auth.service'
import { ApiCreatedResponse } from '@nestjs/swagger'
import { FirebaseCustomTokenResponse } from './models/firebase-custom-token.model'
import { CreateUserWithEmailPasswordDto } from './dto/CreateUserWithEmailPasswordDto'
import { UserService } from '../user/user.service'
import { User } from '../user/user.schema'
import { ApiResponseProperty } from '@nestjs/swagger/dist/decorators/api-property.decorator'
import { PublicFirebaseAuthNotRequired } from './public.decorator'
import { UserBearerToken, UserToken } from './get-user.decorator'
import { FirebaseTokenAuthGuard } from './auth.guard'
import { UserId } from '../util/mongo-object-id-helpers'

export class CreateUserResponse extends User {
  @ApiResponseProperty()
  _id: string
}

export class CreateAuthUserResponse extends User {
  @ApiResponseProperty()
  _id: string
}
/**
 * @description Handles authenticating users through firebase
 */
@UsePipes(new ValidationPipe({ whitelist: true }))
@Controller('auth')
@FirebaseTokenAuthGuard()
export class AuthController {
  private readonly logger = new Logger(AuthController.name)

  constructor(
    private readonly authService: AuthService,
    private readonly userService: UserService
  ) {}

  /*****************************
   PUBLICLY ACCESSIBLE ENDPOINTS
   ****************************/

  @PublicFirebaseAuthNotRequired()
  @Post('email-password')
  @ApiCreatedResponse({
    type: CreateUserResponse
  })
  async createUserWithEmailPasswordAndType(
    @Body() dto: CreateUserWithEmailPasswordDto
  ) {
    const user = await this.userService.createUserWithEmailPassword(dto)
    return { user }
  }

  @FirebaseTokenAuthGuard()
  @Post('auth-user-create')
  @ApiCreatedResponse({ type: () => CreateAuthUserResponse })
  async authedUserCreate(
    @UserBearerToken() token: string
  ): Promise<CreateAuthUserResponse> {
    return await this.userService.ensureMirrorUserExists(token)
  }

  @Post('convert-to-full-account')
  @FirebaseTokenAuthGuard()
  @ApiCreatedResponse({ type: CreateUserResponse })
  async convertAnonymousAccountToFull(
    @UserToken('uid') anonymousUserId: string,
    @Body() createUserWithEmailPasswordDto: CreateUserWithEmailPasswordDto
  ) {
    return await this.authService.convertAnonymousAccountToFull(
      createUserWithEmailPasswordDto,
      anonymousUserId
    )
  }

  @Delete()
  @FirebaseTokenAuthGuard()
  async deleteAccount(@UserToken('user_id') userId: UserId) {
    return await this.authService.markAccountAsDeleted(userId)
  }
}

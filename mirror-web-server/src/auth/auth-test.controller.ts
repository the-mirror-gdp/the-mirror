import {
  Body,
  Controller,
  NotFoundException,
  Post,
  Logger
} from '@nestjs/common'
import { FirebaseAuthenticationService } from '../firebase/firebase-authentication.service'
import { NODE_ENV } from '../util/node-env.enum'

@Controller('auth/test')
export class AuthTestController {
  constructor(
    private readonly logger: Logger,
    private readonly firebaseAuthServiceForTestOnly: FirebaseAuthenticationService
  ) {}

  /**
   * @description Only used in when NODE_ENV === NODE_ENV.TEST for e2e. Deletes the test account. Checks if the email is an e2e email that ends in @themirror.space. This is a POST so that a body can easily be included (no body in DELETE requests)
   * @date 2023-03-16 01:01
   */
  @Post('delete-test-account')
  async deleteTestAccount(@Body() body) {
    const email = body.email
    if (
      email?.includes('e2e') &&
      email?.includes('@themirror.space') &&
      process.env.NODE_ENV === NODE_ENV.TEST
    ) {
      let user
      try {
        user = await this.firebaseAuthServiceForTestOnly.getUserByEmail(email)
      } catch (error) {
        this.logger.warn(error?.message, AuthTestController.name)
      }
      return await this.firebaseAuthServiceForTestOnly.deleteUser(user.uid)
    } else {
      this.logger.warn(
        'Failed to delete test account: ' + email,
        AuthTestController.name
      )
      // shouldn't be here
      throw new NotFoundException()
    }
  }
}

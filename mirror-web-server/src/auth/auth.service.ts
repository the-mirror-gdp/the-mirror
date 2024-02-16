import {
  BadRequestException,
  HttpException,
  Injectable,
  Logger,
  NotFoundException
} from '@nestjs/common'
import { InjectModel } from '@nestjs/mongoose'
import { Model } from 'mongoose'
import { User, UserDocument } from '../user/user.schema'
import { UserService } from '../user/user.service'
import { FirebaseCustomTokenResponse } from './models/firebase-custom-token.model'
import { FirebaseAuthenticationService } from '../firebase/firebase-authentication.service'
import { FirebaseDatabaseService } from '../firebase/firebase-database.service'
import { CreateUserWithEmailPasswordDto } from './dto/CreateUserWithEmailPasswordDto'
import { UserRecord } from 'firebase-admin/lib/auth/user-record'

/**
 * @description Typed stub for now since package types aren't matching
 * @date 2023-06-23 11:46
 */
export type UserRecordStub = any
@Injectable()
export class AuthService {
  constructor(
    private readonly logger: Logger,
    public userService: UserService,
    public firebaseAuthService: FirebaseAuthenticationService,
    private firebaseDB: FirebaseDatabaseService,
    @InjectModel(User.name) private userModel: Model<UserDocument>
  ) {}

  async checkIfUserExistsInFirebase(
    uid: string
  ): Promise<UserRecordStub | false> {
    return await this.firebaseAuthService
      .getUser(uid)
      .then((userRecord) => userRecord)
      .catch((error) => {
        if (error.code == 'auth/user-not-found') {
          return false
        } else {
          this.logger.error(error.message, error)
          throw error
        }
      })
  }

  async checkIfUserExistsInFirebaseByEmail(
    email: string
  ): Promise<UserRecordStub | false> {
    return await this.firebaseAuthService
      .getUserByEmail(email)
      .then((userRecord) => userRecord)
      .catch((error) => {
        if (error.code == 'auth/user-not-found') {
          return false
        } else {
          this.logger.error(error.message, error)
          throw error
        }
      })
  }

  mintACustomToken(
    uid: string,
    additionalClaims?: any
  ): Promise<FirebaseCustomTokenResponse> {
    return this.firebaseAuthService
      .createCustomToken(uid, additionalClaims)
      .then((token) => ({ token }))
      .catch((error) => {
        this.logger.error(error.message, error)
        throw error
      })
  }

  async convertAnonymousAccountToFull(
    createUserWithEmailPasswordDto: CreateUserWithEmailPasswordDto,
    anonymousUserId: string
  ) {
    // disallow creation if they didn't agree to TOS/PP
    if (!createUserWithEmailPasswordDto.termsAgreedtoGeneralTOSandPP) {
      throw new BadRequestException(
        'You must agree to the Terms of Service and Privacy Policy to create an account: https://www.themirror.space/terms, https://www.themirror.space/privacy'
      )
    }

    let anonymous: UserRecord

    try {
      anonymous = await this.firebaseAuthService.getUser(anonymousUserId)
    } catch (err) {
      throw new NotFoundException('User not found')
    }

    const fullUser = await this.firebaseAuthService.updateUser(anonymous.uid, {
      email: createUserWithEmailPasswordDto.email,
      password: createUserWithEmailPasswordDto.password,
      displayName: createUserWithEmailPasswordDto.displayName
    })

    await this.userModel.updateOne(
      { _id: anonymous.uid },
      {
        email: fullUser.email,
        displayName: fullUser.displayName,
        termsAgreedtoGeneralTOSandPP:
          createUserWithEmailPasswordDto.termsAgreedtoGeneralTOSandPP
      }
    )

    return fullUser
  }

  /**
   * @description This method will mark the user as deleted in the database and delete the user firebase account.
   * User with deleted: true property will be filtered from all search results and also we unset the email, firebaseUID and discordId of that user
   * @date 2023-12-22 17:31
   */
  public async markAccountAsDeleted(userId: string) {
    await this.userService.markUserAsDeleted(userId)
    await this.firebaseAuthService.deleteUser(userId)

    return { userId }
  }
}

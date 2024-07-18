import {
  BadRequestException,
  Injectable,
  NotFoundException
} from '@nestjs/common'
import { UserService } from '../user/user.service'
import { UserId } from '../util/mongo-object-id-helpers'
import { ObjectId } from 'mongodb'
import { LoginCode, LoginCodeDocument } from './login-code.schema'
import { InjectModel } from '@nestjs/mongoose'
import { User, UserDocument } from '../user/user.schema'
import { Model } from 'mongoose'
import { SpaceService } from '../space/space.service'
@Injectable()
export class LoginCodeService {
  constructor(
    private readonly userService: UserService,
    @InjectModel(User.name)
    private userModel: Model<UserDocument>,
    private readonly spaceService: SpaceService,
    @InjectModel(LoginCode.name)
    private loginCodeModel: Model<LoginCodeDocument>
  ) {}

  // generate 6 digit login code
  private _generateLoginCode(length = 6): string {
    return Math.random().toString().substr(2, length)
  }

  public async createLoginCode(
    userId: UserId,
    spaceId: string,
    refreshToken: string
  ): Promise<LoginCode> {
    let uniqueLoginCode = this._generateLoginCode()

    const user = await this.userService.findOneAdmin(userId)

    if (!user) {
      throw new BadRequestException('User not found')
    }

    const space = await this.spaceService.findOneAdmin(spaceId)

    if (!space) {
      throw new BadRequestException('Space not found')
    }

    // check if login code is unique
    while (await this.loginCodeModel.findOne({ loginCode: uniqueLoginCode })) {
      uniqueLoginCode = this._generateLoginCode()
    }

    const createdLoginCode = new this.loginCodeModel({
      userId: new ObjectId(userId),
      refreshToken: refreshToken,
      spaceId: new ObjectId(spaceId),
      loginCode: uniqueLoginCode
    })
    return await createdLoginCode.save()
  }

  public async getLoginCodeRecordByLoginCode(
    loginCode: string
  ): Promise<LoginCode> {
    const loginCodeRecord = await this.loginCodeModel
      .findOne({ loginCode: loginCode })
      .exec()
    if (!loginCodeRecord) {
      throw new NotFoundException('Login code not found')
    }
    return loginCodeRecord
  }
}

import { Module } from '@nestjs/common'
import { UserModule } from '../user/user.module'
import { LoggerModule } from '../util/logger/logger.module'
import { MongooseModule } from '@nestjs/mongoose'
import { User, UserSchema } from '../user/user.schema'
import { LoginCodeController } from './login-code.controller'
import { LoginCodeService } from './login-code.service'
import { LoginCode, LoginCodeSchema } from './login-code.schema'
import { SpaceModule } from '../space/space.module'

@Module({
  imports: [
    LoggerModule,
    UserModule,
    SpaceModule,
    MongooseModule.forFeature([
      { name: User.name, schema: UserSchema },
      { name: LoginCode.name, schema: LoginCodeSchema }
    ])
  ],
  controllers: [LoginCodeController],
  providers: [LoginCodeService],
  exports: []
})
export class LoginCodeModule {}

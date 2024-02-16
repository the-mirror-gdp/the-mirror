import { AuthController } from './auth.controller'
import { Module } from '@nestjs/common'
import { AuthService } from './auth.service'
import { UserModule } from '../user/user.module'
import { HttpModule } from '@nestjs/axios'
import { MongooseModule } from '@nestjs/mongoose'
import { User, UserSchema } from '../user/user.schema'
import { AssetModule } from '../asset/asset.module'
import { RoleModule } from '../roles/role.module'
import { AuthTestController } from './auth-test.controller'
import { NODE_ENV } from '../util/node-env.enum'
import { LoggerModule } from '../util/logger/logger.module'

const controllers: any[] = [AuthController]
if (process.env.NODE_ENV === NODE_ENV.TEST) {
  controllers.push(AuthTestController)
}
@Module({
  imports: [
    LoggerModule,
    HttpModule,
    UserModule,
    AssetModule,
    RoleModule,
    MongooseModule.forFeature([{ name: User.name, schema: UserSchema }])
  ],
  controllers,
  providers: [AuthService],
  exports: [AuthService, RoleModule]
})
export class AuthModule {}

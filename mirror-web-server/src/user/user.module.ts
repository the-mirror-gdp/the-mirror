import { Module, forwardRef } from '@nestjs/common'
import { UserService } from './user.service'
import { UserController } from './user.controller'
import { User, UserSchema } from './user.schema'
import { MongooseModule } from '@nestjs/mongoose'
import { UserSearch } from './user.search'
import { FileUploadModule } from '../util/file-upload/file-upload.module'
import {
  UserAccessKey,
  UserAccessKeySchema
} from './models/user-access-key.schema'
import { CustomDataModule } from '../custom-data/custom-data.module'
import { LoggerModule } from '../util/logger/logger.module'
import {
  UserEntityAction,
  UserEntityActionSchema
} from './models/user-entity-action.schema'
import { FirebaseModule } from '../firebase/firebase.module'

@Module({
  imports: [
    FirebaseModule,
    LoggerModule,
    forwardRef(() => FileUploadModule),
    CustomDataModule,
    MongooseModule.forFeature([
      { name: User.name, schema: UserSchema },
      { name: UserAccessKey.name, schema: UserAccessKeySchema },
      { name: UserEntityAction.name, schema: UserEntityActionSchema }
    ])
  ],
  controllers: [UserController],
  providers: [UserService, User, UserSearch],
  exports: [UserService, User]
})
export class UserModule {}

import { LoggerModule } from './../util/logger/logger.module'
import { Module } from '@nestjs/common'
import { MongooseModule } from '@nestjs/mongoose'
import { Role, RoleSchema } from './models/role.schema'
import { RoleService } from './role.service'

@Module({
  imports: [
    LoggerModule,
    MongooseModule.forFeature([
      {
        name: Role.name,
        schema: RoleSchema
      }
    ])
  ],
  controllers: [],
  providers: [RoleService],
  exports: [
    RoleService,
    MongooseModule.forFeature([{ name: Role.name, schema: RoleSchema }])
  ]
})
export class RoleModule {}

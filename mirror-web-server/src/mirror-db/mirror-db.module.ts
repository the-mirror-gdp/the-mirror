import { Module } from '@nestjs/common'
import { MirrorDBService } from './mirror-db.service'
import { MirrorDBController } from './mirror-db.controller'
import { MongooseModule } from '@nestjs/mongoose'
import {
  MirrorDBRecord,
  MirrorDBSchema
} from './models/mirror-db-record.schema'
import { LoggerModule } from '../util/logger/logger.module'
import { MirrorDBGateway } from './mirror-db.gateway'
import { RoleModule } from '../roles/role.module'

@Module({
  imports: [
    LoggerModule,
    MongooseModule.forFeature([
      { name: MirrorDBRecord.name, schema: MirrorDBSchema }
    ]),
    RoleModule
  ],
  providers: [MirrorDBService, MirrorDBGateway],
  exports: [MirrorDBService],
  controllers: [MirrorDBController]
})
export class MirrorDBModule {}

import { Module, forwardRef } from '@nestjs/common'
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
import { SpaceModule } from '../space/space.module'
import { GodotModule } from '../godot-server/godot.module'

@Module({
  imports: [
    LoggerModule,
    GodotModule,
    MongooseModule.forFeature([
      { name: MirrorDBRecord.name, schema: MirrorDBSchema }
    ]),
    RoleModule,
    forwardRef(() => SpaceModule)
  ],
  providers: [MirrorDBService, MirrorDBGateway],
  exports: [MirrorDBService],
  controllers: [MirrorDBController]
})
export class MirrorDBModule {}

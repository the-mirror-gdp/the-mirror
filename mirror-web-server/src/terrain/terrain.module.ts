import { LoggerModule } from './../util/logger/logger.module'
import { Terrain, TerrainSchema } from './terrain.schema'
import { TerrainController } from './terrain.controller'
import { TerrainGateway } from './terrain.gateway'
import { TerrainService } from './terrain.service'
import { MongooseModule } from '@nestjs/mongoose'
import { Module, forwardRef } from '@nestjs/common'
import { FileUploadModule } from '../util/file-upload/file-upload.module'
import { SpaceModule } from '../space/space.module'
import { Space, SpaceSchema } from '../space/space.schema'
import { GodotModule } from '../godot-server/godot.module'

@Module({
  imports: [
    LoggerModule,
    GodotModule,
    MongooseModule.forFeature([{ name: Terrain.name, schema: TerrainSchema }]),
    FileUploadModule,
    forwardRef(() => SpaceModule), // to fix circular dependency
    MongooseModule.forFeature([{ name: Space.name, schema: SpaceSchema }])
  ],
  controllers: [TerrainController],
  providers: [TerrainService, TerrainGateway],
  exports: [TerrainService]
})
export class TerrainModule {}

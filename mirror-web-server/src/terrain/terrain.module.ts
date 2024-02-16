import { LoggerModule } from './../util/logger/logger.module'
import { Terrain, TerrainSchema } from './terrain.schema'
import { TerrainController } from './terrain.controller'
import { TerrainGateway } from './terrain.gateway'
import { TerrainService } from './terrain.service'
import { MongooseModule } from '@nestjs/mongoose'
import { Module } from '@nestjs/common'
import { FileUploadModule } from '../util/file-upload/file-upload.module'

@Module({
  imports: [
    LoggerModule,
    MongooseModule.forFeature([{ name: Terrain.name, schema: TerrainSchema }]),
    FileUploadModule
  ],
  controllers: [TerrainController],
  providers: [TerrainService, TerrainGateway],
  exports: [TerrainService]
})
export class TerrainModule {}

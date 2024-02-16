import { LoggerModule } from './../util/logger/logger.module'
import { Module } from '@nestjs/common'
import { MongooseModule } from '@nestjs/mongoose'
import { FavoriteController } from './favorite.controller'
import { Favorite, FavoriteSchema } from './favorite.schema'
import { FavoriteService } from './favorite.service'

@Module({
  imports: [
    LoggerModule,
    MongooseModule.forFeature([{ name: Favorite.name, schema: FavoriteSchema }])
  ],
  // controllers: [FavoriteController], 2023-05-01 12:54:33 not in use yet.
  providers: [FavoriteService]
})
export class FavoriteModule {}

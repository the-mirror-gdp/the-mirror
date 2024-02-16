import { LoggerModule } from './../util/logger/logger.module'
import { Module } from '@nestjs/common'
import { MongooseModule } from '@nestjs/mongoose'
import { BlockController } from './block.controller'
import { Block, BlockSchema } from './block.schema'
import { BlockService } from './block.service'

@Module({
  imports: [
    LoggerModule,
    MongooseModule.forFeature([{ name: Block.name, schema: BlockSchema }])
  ],
  controllers: [BlockController],
  providers: [BlockService]
})
export class BlockModule {}

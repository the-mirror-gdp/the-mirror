import { Module } from '@nestjs/common'
import { MongooseModule } from '@nestjs/mongoose'
import { SpaceVariablesDataService as SpaceVariablesDataService } from './space-variables-data.service'
import {
  SpaceVariablesData,
  SpaceVariablesDataSchema
} from './models/space-variables-data.schema'

const mongooseParams = [
  {
    name: SpaceVariablesData.name,
    schema: SpaceVariablesDataSchema
  }
]
@Module({
  imports: [MongooseModule.forFeature(mongooseParams)],
  providers: [SpaceVariablesDataService],
  exports: [
    SpaceVariablesDataService,
    MongooseModule.forFeature(mongooseParams)
  ]
})
export class SpaceVariablesDataModule {}

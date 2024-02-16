import { Module } from '@nestjs/common'
import { MongooseModule } from '@nestjs/mongoose'
import { CustomDataService } from './custom-data.service'
import { CustomData, CustomDataSchema } from './models/custom-data.schema'

/**
 * CustomData is a collection of arbitrary data that can be attached to any other collection via customData: ObjectId. This allows a user to store arbitrary data that is not part of the schema of the collection.
 *
 * As of 2023-03-02 21:25:21, there aren't any controller/service methods because CustomData should be retrieved via populate('customData') on the other collection.
 */

const mongooseParams = [
  {
    name: CustomData.name,
    schema: CustomDataSchema
  }
]
@Module({
  imports: [MongooseModule.forFeature(mongooseParams)],
  providers: [CustomDataService],
  exports: [CustomDataService, MongooseModule.forFeature(mongooseParams)]
})
export class CustomDataModule {}

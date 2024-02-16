import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose'
import { ApiProperty } from '@nestjs/swagger'
import { User } from '../../user/user.schema'
import * as mongoose from 'mongoose'
import { Document } from 'mongoose'
import { Space } from '../../space/space.schema'
import { SpaceObject } from '../../space-object/space-object.schema'

export class CustomDataPublicData {}

export type CustomDataDocument = CustomData & Document

/**
 * CustomData is a collection of arbitrary data that can be attached to any other collection via customData: ObjectId[]. This allows a user to store arbitrary data that is not part of the schema of the collection.
 *
 * As of 2023-03-02 21:25:21, there aren't any controller/service methods because CustomData should be retrieved via populate('customData') on the other collection.
 *
 * Reasons for having customData in a separate schema:
 * 1. Clean separation between custom key/value pairs from users and the data TM stores
 * 2. CustomData can be used by multiple collections and "moved" from different schemas
 * 3. CustomData optimizes storage with staying in a separate collection. Otherwise, MongoDB will dynamically expand storage allocated for the collection, which would affect performance as we grow. See this post from a MongoDB tech lead: https://www.askasya.com/post/largeembeddedarrays/
 * 4. We can add validation rules in the customData collection in the future via this schema
 * 5. We can optimize when to populate() customData in case it gets large
 * 6. We can manage indexes ourselves on CustomData
 * 7. We can add discriminators/subclasses for specific use cases, such as whitelabel clients
 * 8. By decoupling CustomData from other entities like Spaces, the same CustomData can be used by multiple Spaces (or any other entity).
 */
@Schema({
  timestamps: true,
  toJSON: {
    virtuals: true
  },
  minimize: false // store empty data: {} upon creation
})
export class CustomData {
  /**
   * @description All customData data is stored in a "data" key (customData.data). Keys of customData.data can be of type string, number, Date, or boolean. (We can add JSON in the future, as well as references to other entities). This is the simplest implementation for now.
   * @date 2023-03-03 22:30
   */
  @Prop({
    type: () => mongoose.Schema.Types.Array,
    default: {},
    required: true
  })
  @ApiProperty()
  data: any

  // @Prop is not used here; a virtual is used instead (below) due to a circular reference issue
  // creator: User
  id: string
}

export const CustomDataSchema = SchemaFactory.createForClass(CustomData)

// Need to use a virtual property here so we don't get a circular reference issue
CustomDataSchema.virtual('creator', {
  ref: 'User',
  localField: 'creator',
  foreignField: '_id',
  select: '_id displayName'
})

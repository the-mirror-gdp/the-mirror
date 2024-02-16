import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose'
import { ApiProperty } from '@nestjs/swagger'
import * as mongoose from 'mongoose'
import { Document } from 'mongoose'
import { Space } from '../../space/space.schema'

export class SpaceVariablesDataPublicData {}

export type SpaceVariablesDataDocument = SpaceVariablesData & Document

/**
 * SpaceVariablesData is a collection of arbitrary data that can be attached to a Space, via spaceVariablesData: ObjectId . This allows a user to store arbitrary data that is not part of the schema of the collection.
 *
 * Note that on 2023-06-05 16:06:26, this was created based on CustomData, which hasn't been implemented on the Godot client yet. I'm not sure if we'll want/need to keep CustomData.
 *
 * The general intent is that there's 1 SpaceVariableDOCUMENT per Space. We can allow for more in the future as a premium feature (Mongo has a 16MB max document size limit).
 *
 * Reasons for having SpaceVariablesData in a separate schema:
 * 1. Clean separation between custom key/value pairs from users and the data TM stores
 * 2. SpaceVariablesData optimizes storage with staying in a separate collection. Otherwise, MongoDB will dynamically expand storage allocated for the collection, which would affect performance as we grow. See this post from a MongoDB tech lead: https://www.askasya.com/post/largeembeddedarrays/
 * 3. We can add validation rules in the SpaceVariablesData collection in the future via this schema
 * 4. We can optimize when to populate() SpaceVariablesData in case it gets large
 * 5. We can manage indexes ourselves on SpaceVariablesData
 */
@Schema({
  timestamps: true,
  toJSON: {
    virtuals: true
  },
  minimize: false // store empty data: {} upon creation
})
export class SpaceVariablesData {
  /**
   * @description All spaceVariable data is stored in a "data" key (spaceVariable.data). Values of spaceVariablesData.data can be of type string, number, Date, JSON, or boolean. It's just a JSON key/value store (dictionary).
   * @date 2023-03-03 22:30
   */
  @Prop({ type: mongoose.Schema.Types.Mixed, default: {}, required: true })
  @ApiProperty()
  data: any

  // @Prop is not used here; a virtual is used instead (below) due to a circular reference issue
  id: string

  @ApiProperty()
  createdAt: Date // this is managed by mongoose timestamps: true, but defining it here so types will align
  @ApiProperty()
  updatedAt: Date // this is managed by mongoose timestamps: true, but defining it here so types will align
}

export const SpaceVariablesDataSchema =
  SchemaFactory.createForClass(SpaceVariablesData)

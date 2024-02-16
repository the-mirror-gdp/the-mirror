import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose'
import { ApiProperty } from '@nestjs/swagger'
import * as mongoose from 'mongoose'
import { Document } from 'mongoose'
import { Asset } from '../asset/asset.schema'
import { Space } from '../space/space.schema'

import { User } from '../user/user.schema'

export type FavoriteDocument = Favorite & Document

/**
 * 2023-05-01 12:54:52 !!This should be refactored to use Mongoose correctly with 1 property instead of a different field for every type of entity
  This schema isn't in use yet
 */

@Schema({
  timestamps: true,
  toJSON: {
    virtuals: true
  }
})
export class Favorite {
  @Prop({
    required: false,
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Asset'
  })
  @ApiProperty()
  asset: Asset

  @Prop({
    required: false,
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Space'
  })
  @ApiProperty()
  land: Space

  @Prop({
    required: false,
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  })
  @ApiProperty()
  user: User

  @Prop({
    required: true,
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  })
  @ApiProperty()
  creator: User
}

export const FavoriteSchema = SchemaFactory.createForClass(Favorite)

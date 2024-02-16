import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose'
import { ApiProperty } from '@nestjs/swagger'
import mongoose from 'mongoose'

export type UserCartItemDocument = UserCartItem & Document

/**
 * @description Only used for entities that can be purchased. Right now this is is just Asset, but in the future, can be a Space, potentialy a SpaceObject (pending any refactoring), a full Space, a script, etc.
 * @date 2023-07-09 16:06
 */
export enum ENTITY_TYPE_AVAILABLE_TO_PURCHASE {
  ASSET = 'ASSET'
  // SPACE_OBJECT?
}

@Schema({
  timestamps: true,
  toJSON: {
    virtuals: true
  }
})
export class UserCartItem {
  @Prop({
    type: mongoose.Types.ObjectId,
    refPath: 'entityType',
    required: true
  })
  @ApiProperty({ type: 'string' })
  forEntity: mongoose.Types.ObjectId

  @Prop({
    required: true,
    enum: ENTITY_TYPE_AVAILABLE_TO_PURCHASE
  })
  @ApiProperty({ type: 'string' })
  entityType: string

  // we aren't including price here since that should be pulled from the source of truth at the time of purchase (from the Asset)
}

export const UserCartItemSchema = SchemaFactory.createForClass(UserCartItem)

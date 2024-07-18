import * as mongoose from 'mongoose'
import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose'
import { ApiProperty } from '@nestjs/swagger'
import { User } from '../user.schema'

export class UserEntityActionPublicData {
  @ApiProperty() // @ApiProperty must be included to be exposed by the API and flow to FE codegen
  _id = '' // Must not be undefined
  @ApiProperty()
  createdAt = new Date()
  @ApiProperty()
  updatedAt = new Date()
  @ApiProperty()
  actionType = ''
  @ApiProperty()
  entityType = ''
  @ApiProperty()
  forEntity = ''
  @ApiProperty()
  creator = ''
  @ApiProperty()
  rating = 5
}

export enum ENTITY_TYPE {
  USER = 'USER',
  SPACE = 'SPACE',
  ASSET = 'ASSET'
}

/**
* @description Business logic:
// Assets: Can be liked
// Spaces: Can be rated
// User: Can be followed
// should we remove save, like? Seems like that functionality could be covered by tags/folders.
*/
export enum USER_ENTITY_ACTION_TYPE {
  LIKE = 'LIKE',
  RATING = 'RATING',
  SAVE = 'SAVE',
  FOLLOW = 'FOLLOW'
}

export type UserEntityActionDocument = UserEntityAction & Document

/**
* @description Likes, ratings, saves, etc. This is a generic class for an action that a user takes on another entity. 
I wasn't feeling certain that we want to call it a "like", so this keeps it general.
Walkthrough: https://www.loom.com/share/76a6644fd0264ec696281285bcfbd22e
* @date 2023-06-14 15:31
*/
@Schema({
  timestamps: true,
  toJSON: {
    virtuals: true
  }
})
export class UserEntityAction {
  @Prop({
    required: true,
    enum: USER_ENTITY_ACTION_TYPE
  })
  actionType: USER_ENTITY_ACTION_TYPE

  @Prop({
    required: true,
    enum: ENTITY_TYPE
  })
  @ApiProperty()
  entityType: ENTITY_TYPE

  @Prop({
    type: mongoose.Types.ObjectId,
    refPath: 'entityType',
    required: true
  })
  @ApiProperty()
  forEntity: mongoose.Types.ObjectId

  @Prop({ type: mongoose.Schema.Types.ObjectId, ref: 'User' })
  @ApiProperty()
  creator: User

  @Prop({
    required: function () {
      return this.actionType === USER_ENTITY_ACTION_TYPE.RATING
    },
    min: 1,
    max: 5
  })
  @ApiProperty()
  rating?: number // for rate actions
}

export const UserEntityActionSchema =
  SchemaFactory.createForClass(UserEntityAction)

// Enforce uniqueness: a user can only take 1 action on an entity with the same actionType (e.g. a user can only like an entity once, BUT could rate it once as well. This allows us flexibility on future business logic, but we for sure know that a user would only be able to like once, rate once, etc.)
UserEntityActionSchema.index(
  { creator: 1, forEntity: 1, actionType: 1 },
  { unique: true }
)

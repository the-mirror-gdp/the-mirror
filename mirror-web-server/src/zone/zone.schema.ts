import { SpaceVersion } from './../space/space-version.schema'
import { Document } from 'mongoose'
import * as mongoose from 'mongoose'
import { User } from '../user/user.schema'
import { ApiProperty } from '@nestjs/swagger'
import { Space } from '../space/space.schema'
import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose'
import { CONTAINER_STATE } from './space-manager-external.service'
export enum ZONE_MODE {
  BUILD = 'BUILD',
  PLAY = 'PLAY'
}
export type ZoneDocument = Zone & Document

@Schema({
  timestamps: true,
  toJSON: {
    virtuals: true
  }
})
export class Zone {
  @Prop({
    required: true,
    default: 'Zone'
  })
  @ApiProperty()
  name: string

  /**
   * @description This is the last time the container was refreshed. It is used to check if a refresh is needed from the space manager to get the latest container status.
   * @date 2023-06-09 00:48
   */
  @Prop()
  @ApiProperty()
  containerLastRefreshed: Date

  @Prop({
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  })
  @ApiProperty()
  owner: User

  @Prop({
    type: [
      {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User'
      }
    ]
  })
  @ApiProperty()
  usersPresent: User[]

  @Prop({
    required: true,
    // must be ZONE_MODE.PLAY if spaceVersion is truthy. See validation pre-save hook below
    default: ZONE_MODE.BUILD,
    enum: ZONE_MODE
  })
  @ApiProperty({
    description: `The mode that the server is in.`,
    enum: ZONE_MODE
  })
  zoneMode: ZONE_MODE

  /**
   * @description The version of the GODOT SERVER that is running on the zone. This is NOT the spaceVersion
   * @date 2023-06-16 16:05
   */
  @Prop({
    required: true
  })
  @ApiProperty()
  gdServerVersion: string

  @Prop({
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Space'
  })
  @ApiProperty()
  space: Space

  @Prop({
    type: mongoose.Schema.Types.ObjectId,
    ref: 'SpaceVersion'
  })
  @ApiProperty()
  spaceVersion?: SpaceVersion

  @Prop()
  @ApiProperty()
  description: string

  @Prop()
  @ApiProperty()
  url: string

  @Prop({
    unique: true
  })
  @ApiProperty()
  uuid: string

  @Prop()
  @ApiProperty()
  ipAddress: string

  @Prop()
  @ApiProperty()
  port: number

  @Prop()
  @ApiProperty()
  state: string

  // virtuals
  // must have this virtual getter (Mongoose virtual). It has to be defined on the schema class but implemented via Schema.methods.userIsOwner = function (userId: string): boolean {...
  isInBadState: () => boolean
}
export const ZoneSchema = SchemaFactory.createForClass(Zone)

ZoneSchema.pre('save', function (next) {
  if (this.zoneMode === ZONE_MODE.PLAY && !this.spaceVersion) {
    const error = new Error(
      `spaceVersion must be truthy if zoneMode===${ZONE_MODE.PLAY}`
    )
    next(error)
  } else {
    next()
  }
})

ZoneSchema.methods.isInBadState = zoneIsInBadStateCheck

/**
 * @description Exported for testing
 * @date 2023-06-06 00:03
 */
export function zoneIsInBadStateCheck() {
  return !this.uuid || this.state == CONTAINER_STATE.ERROR
}

ZoneSchema.index({ space: 1 })

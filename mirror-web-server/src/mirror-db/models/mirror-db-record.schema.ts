import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose'
import { ApiProperty } from '@nestjs/swagger'
import * as mongoose from 'mongoose'
import { Document } from 'mongoose'

export type MirrorDBRecordDocument = MirrorDBRecord & Document

@Schema({
  timestamps: true,
  toJSON: {
    virtuals: true
  },
  minimize: false
})
export class MirrorDBRecord {
  @Prop({ type: mongoose.Schema.Types.Mixed, default: {}, required: true })
  @ApiProperty()
  recordData: Record<string, unknown>

  @Prop({
    required: true,
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Space'
  })
  @ApiProperty()
  space: mongoose.Schema.Types.ObjectId

  @Prop({
    required: true,
    type: [mongoose.Schema.Types.ObjectId],
    ref: 'SpaceVersion',
    default: []
  })
  @ApiProperty()
  spaceVersions: mongoose.Schema.Types.ObjectId[]
}

export const MirrorDBSchema = SchemaFactory.createForClass(MirrorDBRecord)

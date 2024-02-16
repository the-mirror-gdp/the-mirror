import mongoose, { Document } from 'mongoose'
import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose'

export type SpaceVersionDocument = SpaceVersion & Document

@Schema({
  timestamps: true,
  toJSON: {
    virtuals: true
  }
})
export class SpaceVersion {
  @Prop({ required: true, type: String })
  spaceId: string

  /**
   * @description User-defined name of the SpaceVersion. This is optional in case they don't want to name it.
   * @date 2023-06-10 23:31
   */
  @Prop({ required: false, type: String })
  name: string

  // the space is stored as Map because it is a deep copy.
  @Prop({ type: mongoose.Schema.Types.Map })
  space: any

  // variables is stored as a Map because it is a deep copy.
  @Prop({ type: mongoose.Schema.Types.Map })
  spaceVariables: any

  // the environment is stored as Map because it is a deep copy.
  @Prop({ type: mongoose.Schema.Types.Map })
  environment: any

  // the spaceObjects are stored as Maps because they are deep copies.
  @Prop([mongoose.Schema.Types.Map])
  spaceObjects: any[]

  // the assets are stored as Maps because they are deep copies.
  @Prop([mongoose.Schema.Types.Map])
  assets: any[]

  // the scripts are stored as Maps because they are deep copies.
  @Prop([mongoose.Schema.Types.Map])
  scripts: any[]

  // Space script instances are global scripts attached to the space itself.
  @Prop([mongoose.Schema.Types.Map])
  scriptInstances: any[]

  @Prop(String)
  // the live binary version (both game server and client binaries) at the time of publishing.
  mirrorVersion: string

  @Prop({
    type: mongoose.Types.ObjectId,
    required: true,
    ref: 'MirrorDBRecord'
  })
  mirrorDBRecord: mongoose.Types.ObjectId
}

export const SpaceVersionSchema = SchemaFactory.createForClass(SpaceVersion)

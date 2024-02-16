import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose'
import { ApiProperty } from '@nestjs/swagger'
import mongoose from 'mongoose'

export type GodotServerOverrideConfigDocument = GodotServerOverrideConfig &
  Document

@Schema({
  timestamps: true,
  toJSON: {
    virtuals: true
  }
})
export class GodotServerOverrideConfig {
  @Prop({ required: true })
  @ApiProperty()
  spaceId: string

  _id: mongoose.Types.ObjectId
}

export const GodotServerOverrideConfigSchema = SchemaFactory.createForClass(
  GodotServerOverrideConfig
)

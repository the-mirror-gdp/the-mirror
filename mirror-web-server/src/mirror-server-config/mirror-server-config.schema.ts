import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose'
import { Document } from 'mongoose'
import { ApiProperty } from '@nestjs/swagger'

export type MirrorServerConfigDocument = MirrorServerConfig & Document

@Schema({
  timestamps: true,
  toJSON: {
    virtuals: true
  }
})
export class MirrorServerConfig {
  @Prop({
    required: true
  })
  @ApiProperty()
  gdServerVersion: string
}

export const MirrorServerConfigSchema =
  SchemaFactory.createForClass(MirrorServerConfig)

import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose'
import { ApiProperty } from '@nestjs/swagger'
import * as mongoose from 'mongoose'

export type MaterialInstanceDocument = MaterialInstance & Document

@Schema({
  timestamps: true,
  toJSON: {
    virtuals: true
  },
  strict: false // TEMP allowed until we lock down the structure for game logic
})
export class MaterialInstance {
  @Prop({ type: mongoose.Schema.Types.Map })
  @ApiProperty()
  parameters: any

  _id: string
}

export const MaterialInstanceSchema =
  SchemaFactory.createForClass(MaterialInstance)

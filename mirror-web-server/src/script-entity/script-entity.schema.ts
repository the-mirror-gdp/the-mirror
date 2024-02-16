import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose'
import { ApiProperty } from '@nestjs/swagger'
import * as mongoose from 'mongoose'

export type ScriptEntityDocument = ScriptEntity & Document

@Schema({
  timestamps: true,
  toJSON: {
    virtuals: true
  },
  strict: false // TEMP allowed until we lock down the structure for game logic
})
export class ScriptEntity {
  @Prop([mongoose.Schema.Types.Map])
  @ApiProperty()
  blocks: any[]

  _id: string
}

export const ScriptEntitySchema = SchemaFactory.createForClass(ScriptEntity)

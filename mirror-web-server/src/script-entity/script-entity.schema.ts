import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose'
import { ApiProperty } from '@nestjs/swagger'
import * as mongoose from 'mongoose'
import { Role, RoleSchema } from '../roles/models/role.schema'

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

  @Prop({
    required: false,
    type: RoleSchema
  })
  @ApiProperty()
  role: Role

  @Prop({
    required: false,
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  })
  @ApiProperty()
  creator: mongoose.Schema.Types.ObjectId

  _id: string
}

export const ScriptEntitySchema = SchemaFactory.createForClass(ScriptEntity)

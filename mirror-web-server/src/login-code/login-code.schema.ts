import { Prop, SchemaFactory, Schema } from '@nestjs/mongoose'
import { ApiProperty } from '@nestjs/swagger'
import mongoose from 'mongoose'
import { User } from '../user/user.schema'
import { Space } from '../space/space.schema'

export type LoginCodeDocument = LoginCode & Document

@Schema({
  timestamps: true,
  toJSON: {
    virtuals: true
  }
})
export class LoginCode {
  @Prop({ type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true })
  @ApiProperty()
  userId: User

  @Prop({ required: true, type: String })
  @ApiProperty()
  refreshToken: string

  @Prop({ type: mongoose.Schema.Types.ObjectId, ref: 'Space', required: true })
  @ApiProperty()
  spaceId: Space

  @Prop({ required: true, type: String, unique: true })
  @ApiProperty()
  loginCode: string
}

export const LoginCodeSchema = SchemaFactory.createForClass(LoginCode)

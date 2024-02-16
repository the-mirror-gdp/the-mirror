import * as mongoose from 'mongoose'
import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose'
import { ApiProperty } from '@nestjs/swagger'
import { User } from '../user.schema'
import { PREMIUM_ACCESS } from '../../option-sets/premium-tiers'

export type UserAccessKeyDocument = UserAccessKey & Document

@Schema({
  timestamps: true,
  toJSON: {
    virtuals: true
  }
})
export class UserAccessKey {
  @Prop({ required: true, default: Math.random() })
  @ApiProperty()
  key: string

  @Prop({
    required: true,
    default: PREMIUM_ACCESS.CLOSED_ALPHA,
    enum: PREMIUM_ACCESS,
    type: String
  })
  @ApiProperty({ enum: PREMIUM_ACCESS })
  premiumAccess: PREMIUM_ACCESS

  @Prop({ type: mongoose.Schema.Types.ObjectId, ref: 'User' })
  @ApiProperty()
  usedBy: User

  @Prop()
  adminNote: string
}

export const UserAccessKeySchema = SchemaFactory.createForClass(UserAccessKey)

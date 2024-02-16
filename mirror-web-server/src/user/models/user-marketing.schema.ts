import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose'
import { ApiProperty } from '@nestjs/swagger'

export enum USER_MARKETING_EMAILS {
  FIRST_WELCOME_EMAIL = 'firstWelcomeEmail',
  SIGN_UP_FLOW_USER_HASNT_PLAYED_IN_1_DAY = 'signUpFlowUserHasntPlayedIn1Day',
  SIGN_UP_FLOW_USER_HASNT_LOGGED_IN_13_DAYS = 'signUpFlowUserHasntLoggedIn13Days',
  SIGN_UP_FLOW_USER_HASNT_LOGGED_IN_27_DAYS = 'signUpFlowUserHasntLoggedIn27Days',
  SIGN_UP_FLOW_USER_HASNT_LOGGED_IN_57_DAYS = 'signUpFlowUserHasntLoggedIn57Days',
  SIGN_UP_FLOW_USER_HASNT_LOGGED_IN_87_DAYS = 'signUpFlowUserHasntLoggedIn87Days'
}

export type UserMarketingDocument = UserMarketing & Document

@Schema({
  timestamps: false,
  toJSON: {
    virtuals: true
  },
  _id: false
})
export class UserMarketing {
  @Prop({
    type: [String],
    default: []
  })
  @ApiProperty()
  emailsSent?: string[]
}

export const UserMarketingSchema = SchemaFactory.createForClass(UserMarketing)

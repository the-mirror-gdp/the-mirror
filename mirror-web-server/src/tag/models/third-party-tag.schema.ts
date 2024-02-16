import * as mongoose from 'mongoose'
import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose'
import { ApiProperty } from '@nestjs/swagger'
import { TagPublicData } from './tag.schema'
import { User } from '../../user/user.schema'

export class ThirdPartySourceTagPublicData extends TagPublicData {
  @ApiProperty()
  thirdPartySourceHomePageUrl = ''
  @ApiProperty()
  thirdPartySourcePublicDescription = ''
  @ApiProperty()
  thirdPartySourceTwitterUrl = ''
  @ApiProperty()
  thirdPartySourceTMUserId = ''
}

export type ThirdPartySourceTagDocument = ThirdPartySourceTag & Document

@Schema({
  timestamps: true,
  toJSON: {
    virtuals: true
  }
  // discriminatorKey: __t <- don't uncomment this line: this line is to note that __t is the Mongoose default discriminator key that we use for simplicity rather than specifying our own discriminator key. When this schema is instantiated, __t is "ThirdPartySourceTag". See https://mongoosejs.com/docs/discriminators.html#discriminator-keys. Walkthrough: https://www.loom.com/share/7e09d2777ef94368bcd5fd8c8341b5ef
})
export class ThirdPartySourceTag {
  // Note: use the parent Tag `name` field for the public-facing display name

  @Prop({
    required: true
  })
  @ApiProperty({
    example: 'https://ambientcg.com/'
  })
  thirdPartySourceHomePageUrl: string

  /**
   * Optional
   */
  @Prop({
    required: false
  })
  @ApiProperty({
    example:
      'Ambient CG is a collection of ____ generously provided to the public domain by _____',
    description: 'Use this to shout out to the third party creator.'
  })
  thirdPartySourcePublicDescription: string

  @Prop({
    required: false
  })
  @ApiProperty({
    example: 'https://twitter.com/jareddmccluskey',
    description: 'Optional Twitter url of the third party creator'
  })
  thirdPartySourceTwitterUrl: string

  @Prop({
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: false
  })
  @ApiProperty({
    example: '63e7d34ce147e732d3c87fff',
    description:
      'A MongoDB ObjectID user ID of the creator (if they have a TM account they publicly share).'
  })
  thirdPartySourceTMUserId: User
}

export const ThirdPartySourceTagSchema =
  SchemaFactory.createForClass(ThirdPartySourceTag)

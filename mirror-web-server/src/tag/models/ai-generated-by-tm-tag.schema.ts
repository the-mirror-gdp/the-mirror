import { Schema, SchemaFactory } from '@nestjs/mongoose'
import { TagPublicData } from './tag.schema'

export class AIGeneratedByTMTagPublicData extends TagPublicData {}

export type AIGeneratedByTMTagDocument = AIGeneratedByTMTag & Document

/**
 * @description This is used to denote something created by AI Gen BY THE MIRROR (including TM whitelabeling an AI gen process). This is an important distinction because there may also be another user-facing tag for AI generated content that is not created by TM (such as if a user wants to view all user-generated content that was created by AI, imported from outside The Mirror)
 * @date 2023-02-12 01:48
 */
@Schema({
  timestamps: true,
  toJSON: {
    virtuals: true
  }
  // discriminatorKey: __t <- don't uncomment this line: this line is to note that __t is the Mongoose default discriminator key that we use for simplicity rather than specifying our own discriminator key. When this schema is instantiated, __t is "AIGeneratedByTMTag". See https://mongoosejs.com/docs/discriminators.html#discriminator-keys. Walkthrough: https://www.loom.com/share/7e09d2777ef94368bcd5fd8c8341b5ef
})
export class AIGeneratedByTMTag {}

export const AIGeneratedByTMTagSchema =
  SchemaFactory.createForClass(AIGeneratedByTMTag)

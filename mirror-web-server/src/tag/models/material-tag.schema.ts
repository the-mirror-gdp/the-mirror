import { Schema, SchemaFactory } from '@nestjs/mongoose'
import { TagPublicData } from './tag.schema'

export class MaterialTagPublicData extends TagPublicData {}

export type MaterialTagDocument = MaterialTag & Document

@Schema({
  timestamps: true,
  toJSON: {
    virtuals: true
  }
  // discriminatorKey: __t <- don't uncomment this line: this line is to note that __t is the Mongoose default discriminator key that we use for simplicity rather than specifying our own discriminator key. When this schema is instantiated, __t is "MaterialTag". See https://mongoosejs.com/docs/discriminators.html#discriminator-keys. Walkthrough: https://www.loom.com/share/7e09d2777ef94368bcd5fd8c8341b5ef
})
export class MaterialTag {}

export const MaterialTagSchema = SchemaFactory.createForClass(MaterialTag)

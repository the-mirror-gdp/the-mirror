import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose'
import { ApiProperty } from '@nestjs/swagger'

export class ThirdPartyTagEntity {
  name: string
  thirdPartySourceHomePageUrl: string

  constructor(name: string, thirdPartySourceHomePageUrl: string) {
    this.name = name
    this.thirdPartySourceHomePageUrl = thirdPartySourceHomePageUrl
  }
}

@Schema({
  timestamps: false,
  toJSON: {
    virtuals: true
  },
  _id: false
})
export class ThirdPartyTag {
  @Prop({ type: String })
  @ApiProperty()
  name: string

  @Prop({ type: String })
  @ApiProperty()
  thirdPartySourceHomePageUrl: string
}
export const ThirdPartyTagSchema = SchemaFactory.createForClass(ThirdPartyTag)

@Schema({
  timestamps: false,
  toJSON: {
    virtuals: true
  },
  _id: false
})
export class Tags {
  @Prop({ type: [String] })
  @ApiProperty()
  search: string[]

  @Prop({ type: [String], select: false })
  @ApiProperty()
  userGenerated: string[]

  @Prop({ type: [ThirdPartyTagSchema] })
  @ApiProperty()
  thirdParty: ThirdPartyTagEntity[]

  @Prop({ type: [String] })
  @ApiProperty()
  spaceGenre: string[]

  @Prop({ type: [String] })
  @ApiProperty()
  material: string[]

  @Prop({ type: [String] })
  @ApiProperty()
  theme: string[]

  @Prop({ type: [String] })
  @ApiProperty()
  aiGenerated: string[]
}
export const TagsSchema = SchemaFactory.createForClass(Tags)

import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose'
import { ApiProperty } from '@nestjs/swagger'
import mongoose, { Document } from 'mongoose'
import { Role, RoleSchema } from '../roles/models/role.schema'
import { ISchemaWithRole } from '../roles/role-consumer.interface'
import { AssetPublicData } from './asset.schema'

// Properties must not be undefined so that getPublicPropertiesForMongooseQuery can work
export class TexturePublicData extends AssetPublicData {
  @ApiProperty()
  textureName = ''
  @ApiProperty()
  textureImageFileHashMD5 = ''
  @ApiProperty()
  textureLowQualityFileHashMD5 = ''
  @ApiProperty()
  textureImagePropertyAppliesTo = ''
}

export type TextureDocument = Texture & Document

@Schema({
  timestamps: true,
  toJSON: {
    virtuals: true
  }
  // discriminatorKey: __t <- don't uncomment this line: this line is to note that __t is the Mongoose default discriminator key that we use for simplicity rather than specifying our own discriminator key. When this schema is instantiated, __t is "Texture". This is DIFFERENT from assetType since we hadn't been using discriminators up until 2023-02-04 18:49:52. See https://mongoosejs.com/docs/discriminators.html#discriminator-keys. Walkthrough: https://www.loom.com/share/7e09d2777ef94368bcd5fd8c8341b5ef
})
export class Texture {
  _id: string
  @Prop({
    trim: true
  })
  @ApiProperty()
  textureImageFileHashMD5: string

  @Prop({
    trim: true
  })
  @ApiProperty()
  textureLowQualityFileHashMD5: string

  @Prop({
    trim: true
  })
  @ApiProperty()
  textureImagePropertyAppliesTo: string

  /**
   * START Section: ISchemaWithRole implementer
   */
  @Prop({
    required: true,
    type: RoleSchema
  })
  @ApiProperty()
  role: Role
  /**
   * END Section: ISchemaWithRole implementer
   */
}

export const TextureSchema = SchemaFactory.createForClass(Texture)

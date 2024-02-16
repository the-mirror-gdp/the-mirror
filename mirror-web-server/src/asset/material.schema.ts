import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose'
import { ApiProperty } from '@nestjs/swagger'
import * as mongoose from 'mongoose'
import { Document } from 'mongoose'
import { Role, RoleSchema } from '../roles/models/role.schema'
import { ISchemaWithRole } from '../roles/role-consumer.interface'
import { AssetPublicData } from './asset.schema'
import { Texture } from './texture.schema'

// Properties must not be undefined so that getPublicPropertiesForMongooseQuery can work
export class MaterialPublicData extends AssetPublicData {
  @ApiProperty({
    example: 'Concrete_super_shiny_example'
  })
  materialName = ''
  @ApiProperty()
  materialTransparencyMode = ''
  @ApiProperty()
  materialTransparencyProperties = ''
  @ApiProperty()
  textures = []
  @ApiProperty()
  externalAssetIds = []
  @ApiProperty()
  parameters = {}
  @ApiProperty()
  materialType = ''
}

export type MaterialDocument = Material & Document

@Schema({
  timestamps: true,
  toJSON: {
    virtuals: true
  }
  // discriminatorKey: __t <- don't uncomment this line: this line is to note that __t is the Mongoose default discriminator key that we use for simplicity rather than specifying our own discriminator key. When this schema is instantiated, __t is "Material". This is DIFFERENT from assetType since we hadn't been using discriminators up until 2023-02-04 18:49:52. See https://mongoosejs.com/docs/discriminators.html#discriminator-keys. Walkthrough: https://www.loom.com/share/7e09d2777ef94368bcd5fd8c8341b5ef
})
export class Material {
  _id: string
  @Prop({
    trim: true
  })
  @ApiProperty({
    example: 'Concrete_super_shiny_example'
  })
  materialName: string

  /**
   * @deprecated This is now a custom setting dependant on material type
   * @date 2023-09-29
   */
  @Prop({
    trim: true
  })
  @ApiProperty()
  materialTransparencyMode: string

  /**
   * @deprecated This is now a custom setting dependant on material type
   * @date 2023-09-29
   */
  @Prop({
    trim: true
  })
  @ApiProperty()
  materialTransparencyProperties: string

  /**
   * @deprecated This information is contained in external_asset_ids
   * @date 2023-09-29
   */
  @Prop({ type: [mongoose.Schema.Types.ObjectId], ref: 'Texture' })
  @ApiProperty()
  textures: Texture[]

  @Prop({ type: [mongoose.Schema.Types.ObjectId], ref: 'Texture' })
  @ApiProperty()
  externalAssetIds: Texture[]

  @Prop({ type: mongoose.Schema.Types.Map })
  @ApiProperty()
  parameters: any

  @Prop({
    required: false,
    trim: true
  })
  @ApiProperty()
  materialType: string

  @Prop()
  @ApiProperty()
  code: string

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

export const MaterialSchema = SchemaFactory.createForClass(Material)

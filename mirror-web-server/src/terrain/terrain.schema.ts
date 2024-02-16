import { Document } from 'mongoose'
import * as mongoose from 'mongoose'
import { ApiProperty } from '@nestjs/swagger'
import { NOISE_TYPE } from '../option-sets/noise-type'
import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose'
import { TERRAIN_MATERIAL } from '../option-sets/terrain-materials'
import { TERRAIN_GENERATOR } from '../option-sets/terrain-generator'
import { User } from '../user/user.schema'

export type TerrainDocument = Terrain & Document

@Schema({
  timestamps: true,
  toJSON: {
    virtuals: true
  }
})
export class Terrain {
  @Prop({ required: true })
  @ApiProperty()
  name: string

  @Prop()
  @ApiProperty()
  description: string

  @Prop({
    required: true,
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  })
  @ApiProperty()
  owner: mongoose.Schema.Types.ObjectId

  @Prop({ default: false })
  @ApiProperty()
  public: boolean

  @Prop({
    default: 0
  })
  @ApiProperty()
  positionX: number

  @Prop({
    default: 0
  })
  @ApiProperty()
  positionY: number

  @Prop({
    default: 0
  })
  @ApiProperty()
  positionZ: number

  @Prop({
    required: true,
    default: TERRAIN_GENERATOR.StandardFastNoiseLight,
    type: String,
    enum: TERRAIN_GENERATOR
  })
  @ApiProperty()
  generator: string

  @Prop({
    required: true,
    default: TERRAIN_MATERIAL.MARS,
    type: String,
    enum: TERRAIN_MATERIAL
  })
  @ApiProperty({ enum: TERRAIN_MATERIAL })
  material: string

  @Prop({
    required: true,
    type: String,
    default: NOISE_TYPE.TYPE_SIMPLEX_SMOOTH
  })
  @ApiProperty({ enum: NOISE_TYPE })
  noiseType: string

  @Prop({
    default: 0
  })
  @ApiProperty()
  seed: number

  @Prop({
    default: -20
  })
  @ApiProperty()
  heightStart: number

  @Prop({
    default: 30
  })
  @ApiProperty()
  heightRange: number

  @ApiProperty()
  createdAt: Date // this is managed by mongoose timestamps: true, but defining it here so types will align
  @ApiProperty()
  updatedAt: Date // this is managed by mongoose timestamps: true, but defining it here so types will align
}

export const TerrainSchema = SchemaFactory.createForClass(Terrain)

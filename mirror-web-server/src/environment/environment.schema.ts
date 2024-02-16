import { ApiProperty } from '@nestjs/swagger'
import mongoose, { Document } from 'mongoose'
import { Light } from '../godot-types/light.schema'
import { Clouds, CloudsSchema } from '../godot-types/clouds.schema'
import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose'
import { Vector3AsArray } from '../option-sets/vectors'

export type EnvironmentDocument = Environment & Document

@Schema({
  timestamps: true,
  toJSON: {
    virtuals: true
  }
})
export class Environment {
  @ApiProperty()
  _id: string

  @Prop({
    required: true,
    default: [0.05882353, 0.05882353, 0.05882353],
    type: mongoose.Types.Array
  })
  @ApiProperty()
  skyTopColor: Vector3AsArray

  @Prop({
    required: true,
    default: [0.1372549, 0.1372549, 0.1372549],
    type: mongoose.Types.Array
  })
  @ApiProperty()
  skyHorizonColor: Vector3AsArray

  @Prop({
    required: true,
    default: [0.18431373, 0.18431373, 0.16862745],
    type: mongoose.Types.Array
  })
  @ApiProperty()
  skyBottomColor: Vector3AsArray

  @Prop({
    required: true,
    default: 1
  })
  @ApiProperty()
  sunCount: number

  @Prop()
  @ApiProperty()
  suns: Light[]

  @Prop({
    required: true,
    default: false
  })
  @ApiProperty()
  fogEnabled: boolean

  @Prop({
    default: true
  })
  @ApiProperty()
  fogVolumetric: boolean

  @Prop({
    default: 0.01
  })
  @ApiProperty()
  fogDensity: number

  @Prop({
    default: [0.8, 0.9, 1.0],
    type: mongoose.Types.Array
  })
  @ApiProperty()
  fogColor: Vector3AsArray

  @Prop({
    required: true,
    default: true
  })
  @ApiProperty()
  ssao: boolean

  @Prop({
    required: true,
    default: true
  })
  @ApiProperty()
  glow: boolean

  @Prop({
    required: true,
    default: 1.0
  })
  @ApiProperty()
  glowHdrThreshold: number

  @Prop({
    required: true,
    default: 'medium'
  })
  @ApiProperty()
  shadowsPreset: string

  @Prop({
    required: true,
    default: false
  })
  @ApiProperty()
  globalIllumination: boolean

  @Prop({
    required: true,
    default: 'physical_sky'
  })
  @ApiProperty()
  environment: string

  @Prop({
    required: true,
    default: 2
  })
  @ApiProperty()
  tonemap: number

  @Prop({ type: CloudsSchema, required: false })
  @ApiProperty({ type: () => Clouds })
  clouds: Clouds

  @Prop({ type: Boolean, required: false, default: false })
  @ApiProperty({ type: () => Boolean, required: false, default: false })
  ssr?: boolean

  @ApiProperty()
  createdAt: Date // this is managed by mongoose timestamps: true, but defining it here so types will align
  @ApiProperty()
  updatedAt: Date // this is managed by mongoose timestamps: true, but defining it here so types will align
}

export const EnvironmentSchema = SchemaFactory.createForClass(Environment)

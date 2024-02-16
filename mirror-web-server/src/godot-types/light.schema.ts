import * as mongoose from 'mongoose'
import { ApiProperty } from '@nestjs/swagger'
import { Document } from 'mongoose'
import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose'
import { Vector2AsArray, Vector3AsArray } from '../option-sets/vectors'

export enum LIGHT_TYPE {
  DIRECTIONAL = 'DIRECTIONAL',
  OMNI = 'OMNI',
  SPOT = 'SPOT'
}

export type LightDocument = Light & Document

@Schema({
  timestamps: true,
  toJSON: {
    virtuals: true
  }
})
export class Light {
  @Prop({
    required: true,
    default: LIGHT_TYPE.SPOT,
    enum: Object.values(LIGHT_TYPE)
  })
  @ApiProperty()
  lightType: LIGHT_TYPE

  // For all lights. Typically on a range of 0.0 to 1.0, but can go above 1.0. Cannot be negative.
  @Prop({
    required: true,
    default: [1.0, 1.0, 1.0]
  })
  @ApiProperty()
  color: Vector3AsArray

  // For all lights. Can be negative.
  @Prop({
    required: true,
    default: 1.0
  })
  @ApiProperty()
  brightness: number

  // Only for directional and spot lights. Allowed on omni, but visually does nothing.
  @Prop({
    default: [0.0, 0.0]
  })
  @ApiProperty()
  rotation: Vector2AsArray

  // Only for omni and spot lights. Allowed on directional, but visually does nothing.
  @Prop({
    default: [0.0, 0.0, 0.0]
  })
  @ApiProperty()
  position: Vector3AsArray

  // Only for omni and spot lights. Cannot be set on directional on the Godot side.
  @Prop({
    default: 5.0
  })
  @ApiProperty()
  range: number

  // Only for spot lights. Cannot be set on directional or omni on the Godot side.
  @Prop({
    default: 45.0
  })
  @ApiProperty()
  spotAngleDegrees: number
}

export const LightSchema = SchemaFactory.createForClass(Light)

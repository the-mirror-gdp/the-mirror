import * as mongoose from 'mongoose'
import { ApiProperty } from '@nestjs/swagger'
import { Document } from 'mongoose'
import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose'
import { Vector3AsArray } from '../option-sets/vectors'

export type CloudsDocument = Clouds & Document

@Schema({
  timestamps: true,
  toJSON: {
    virtuals: true
  }
})
export class Clouds {
  //  For all clouds
  @Prop({
    required: true,
    default: [1.0, 1.0, 1.0],
    type: [Number]
  })
  @ApiProperty()
  albedo: number[] // Vector3AsArray is causing the build to fail for some reason

  // For all clouds.
  @Prop({
    required: true,
    default: 0.6
  })
  @ApiProperty()
  coverage: number

  // For fog-based clouds only.
  @Prop({
    required: true,
    default: 200.0
  })
  @ApiProperty()
  height: number

  // For all clouds.
  @Prop({
    required: true,
    default: 0.02
  })
  @ApiProperty()
  timeScale: number

  // For all clouds.
  @Prop({
    required: true,
    default: false
  })
  @ApiProperty()
  visible: boolean
}

export const CloudsSchema = SchemaFactory.createForClass(Clouds)

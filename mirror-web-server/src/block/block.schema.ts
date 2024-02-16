import * as mongoose from 'mongoose'
import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose'
import { ApiProperty } from '@nestjs/swagger'
import { BLOCK_TYPE } from '../option-sets/block-type'
import { User } from '../user/user.schema'

export class BlockPublicData {
  @ApiProperty() // @ApiProperty must be included to be exposed by the API and flow to FE codegen
  _id = '' // Must not be undefined
  @ApiProperty()
  createdAt = new Date()
  @ApiProperty()
  updatedAt = new Date()
  @ApiProperty()
  name = ''
  @ApiProperty()
  description = ''
  @ApiProperty({ enum: BLOCK_TYPE })
  blockType = ''
}

export type BlockDocument = Block & Document

@Schema({
  timestamps: true,
  toJSON: {
    virtuals: true
  },
  strict: false // TEMP allowed until we lock down the structure for game logic
})
export class Block {
  /**
   * @description Human-readable name that the user will see for this block. The maxlength is arbitrary.
   * @date 2022-12-13 16:46
   */
  @Prop({ required: true, maxlength: 255 })
  @ApiProperty()
  name: string

  @Prop({
    required: false,
    default: BLOCK_TYPE.GENERIC,
    type: String,
    enum: BLOCK_TYPE
  })
  @ApiProperty({ enum: BLOCK_TYPE })
  blockType: string

  /**
   * @description Human-readable name that the user will see for this block. The maxlength is arbitrary.
   * @date 2022-12-13 16:46
   */
  @Prop()
  @ApiProperty({ required: false, maxLength: 1000 })
  description: string

  /**
   * @description Who the block was created by. This will be a TM account if is true
   * @date 2022-12-13 16:46
   */
  @Prop({
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  })
  @ApiProperty()
  creator: User

  /**
   * @description Whether the block is available to the public for all to use. This should be for general Mirror-provided blocks
   * @date 2022-12-13 16:45
   */
  @Prop({
    required: true,
    default: false
  })
  @ApiProperty()
  mirrorPublicLibrary: boolean
}

export const BlockSchema = SchemaFactory.createForClass(Block)

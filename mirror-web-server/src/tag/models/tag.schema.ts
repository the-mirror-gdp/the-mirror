import * as mongoose from 'mongoose'
import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose'
import { ApiProperty } from '@nestjs/swagger'
import { User } from '../../user/user.schema'
import { TAG_TYPE } from '../../option-sets/tag-type'

/**
 * By default, all Tags are viewable and usable by anyone.
 * Tags are only CREATED by The Mirror, UNLESS it's a user-generated Tag (and then, __t is "UserGeneratedTag").
 */

export class TagPublicData {
  @ApiProperty()
  name = ''
  @ApiProperty()
  parentTag = ''
  @ApiProperty()
  tagType = TAG_TYPE.USER_GENERATED // ONLY used for the API. We don't store tagType in the document bc it's redundant with the discriminator key, __t
  @ApiProperty()
  creator = ''
}

export type TagDocument = Tag & Document

@Schema({
  timestamps: true,
  toJSON: {
    virtuals: true
  }
})
export class Tag {
  @Prop({ required: true })
  @ApiProperty({
    description: 'Public-facing name of the Tag'
  })
  name: string

  // High-level approach: A Tag's visibility depends on what it's attached to.
  // Note: 2023-09-03 00:00:29 I removed this property since it was super confusing as to whether the tag meant that the asset is in the mirrorPublicLibrary. However, Asset.mirrorPublicLibrary is what should be used to determine whether something is in the mirrorPublicLibrary
  // mirrorPublicLibrary?: boolean

  // 2023-09-03 00:01:30 This was also removed because whether a tag is public should be determined by the Asset, not by the Tag itself.
  // public?: boolean

  @Prop({ type: mongoose.Schema.Types.ObjectId, ref: 'Tag' })
  @ApiProperty({
    description:
      'A tag can optionally have a parent Tag for categorization, such as hierarchical grouping'
  })
  parentTag?: Tag

  /**
   * @description Needed since we allow for user-created Tags. When it's created by TM, we should use the TM Asset Manager account so that the creator User IDs are consistent
   * @date 2023-02-11 18:47
   */
  @Prop({ type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true })
  @ApiProperty()
  creator: User
}

export const TagSchema = SchemaFactory.createForClass(Tag)

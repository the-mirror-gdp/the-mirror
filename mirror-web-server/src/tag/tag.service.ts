import { Injectable } from '@nestjs/common'
import { InjectModel } from '@nestjs/mongoose'
import { Model } from 'mongoose'
import { TAG_TYPE } from '../option-sets/tag-type'
import {
  CreateTagDto,
  CreateThirdPartySourceTagDto
} from './dto/create-tag.dto'
import { UpdateTagDto } from './dto/update-tag.dto'
import {
  AIGeneratedByTMTag,
  AIGeneratedByTMTagDocument
} from './models/ai-generated-by-tm-tag.schema'
import { ThemeTag, ThemeTagDocument } from './models/asset-theme-tag.schema'
import { MaterialTag, MaterialTagDocument } from './models/material-tag.schema'
import {
  SpaceGenreTag,
  SpaceGenreTagDocument
} from './models/space-genre-tag.schema'
import { Tag, TagDocument } from './models/tag.schema'
import {
  ThirdPartySourceTag,
  ThirdPartySourceTagDocument
} from './models/third-party-tag.schema'
import {
  UserGeneratedTag,
  UserGeneratedTagDocument
} from './models/user-generated-tag.schema'

@Injectable()
export class TagService {
  constructor(
    @InjectModel(Tag.name) private tagModel: Model<TagDocument>,
    @InjectModel(UserGeneratedTag.name)
    private userGeneratedTagModel: Model<UserGeneratedTagDocument>,
    @InjectModel(ThemeTag.name)
    private themeTagModel: Model<ThemeTagDocument>,
    @InjectModel(SpaceGenreTag.name)
    private spaceGenreTagModel: Model<SpaceGenreTagDocument>,
    @InjectModel(MaterialTag.name)
    private materialTagModel: Model<MaterialTagDocument>,
    @InjectModel(ThirdPartySourceTag.name)
    private thirdPartySourceTagModel: Model<ThirdPartySourceTagDocument>,
    @InjectModel(AIGeneratedByTMTag.name)
    private aiGeneratedByTMTagModel: Model<AIGeneratedByTMTagDocument>
  ) {}

  // note that there isn't a way to create a general Tag without a discriminator currently (2023-02-12 00:40:07). We can add that, but if a TAG_TYPE isn't specified, I think it makes sense to default to a USER_GENERATED tag

  createUserGeneratedTag(
    createTagDto: CreateTagDto & { creatorId: string }
  ): Promise<UserGeneratedTagDocument> {
    const created = new this.userGeneratedTagModel({
      creator: createTagDto.creatorId,
      ...createTagDto
    })
    return created.save()
  }

  createThemeTag(
    createTagDto: CreateTagDto & { creatorId: string }
  ): Promise<ThemeTagDocument> {
    const created = new this.themeTagModel({
      creator: createTagDto.creatorId,
      ...createTagDto
    })
    return created.save()
  }

  createSpaceGenreTag(
    createTagDto: CreateTagDto & { creatorId: string }
  ): Promise<SpaceGenreTagDocument> {
    const created = new this.spaceGenreTagModel({
      creator: createTagDto.creatorId,
      ...createTagDto
    })
    return created.save()
  }

  createMaterialTag(
    createTagDto: CreateTagDto & { creatorId: string }
  ): Promise<MaterialTagDocument> {
    const created = new this.materialTagModel({
      creator: createTagDto.creatorId,
      ...createTagDto
    })
    return created.save()
  }

  createThirdPartySourceTag(
    createTagDto: CreateThirdPartySourceTagDto & { creatorId: string }
  ): Promise<ThirdPartySourceTagDocument> {
    const created = new this.thirdPartySourceTagModel({
      creator: createTagDto.creatorId,
      thirdPartySourceHomePageUrl: createTagDto.thirdPartySourceHomePageUrl,
      thirdPartySourcePublicDescription:
        createTagDto.thirdPartySourcePublicDescription,
      thirdPartySourceTwitterUrl: createTagDto.thirdPartySourceTwitterUrl,
      thirdPartySourceTMUserId: createTagDto.thirdPartySourceTMUserId,
      ...createTagDto
    })
    return created.save()
  }

  createAIGeneratedByTMTag(
    createTagDto: CreateTagDto & { creatorId: string }
  ): Promise<AIGeneratedByTMTagDocument> {
    const created = new this.aiGeneratedByTMTagModel({
      creator: createTagDto.creatorId,
      ...createTagDto
    })
    return created.save()
  }

  getTagTypes(): string[] {
    return Object.values(TAG_TYPE)
  }

  findOne(id: string): Promise<TagDocument> {
    return this.tagModel.findById(id).exec()
  }

  findAllMirrorPublicLibraryTags(): Promise<TagDocument[]> {
    return this.tagModel
      .find({
        mirrorPublicLibrary: true
      })
      .exec()
  }

  findAllThemeTags(): Promise<TagDocument[]> {
    return this.tagModel
      .find({
        __t: 'ThemeTag'
      })
      .exec()
  }

  update(id: string, updateTagDto: UpdateTagDto): Promise<TagDocument> {
    return this.tagModel
      .findByIdAndUpdate(id, updateTagDto, { new: true })
      .exec()
  }

  remove(id: string): Promise<TagDocument> {
    return this.tagModel
      .findOneAndDelete({ _id: id })
      .exec() as any as Promise<TagDocument>
  }
}

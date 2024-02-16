import { LoggerModule } from './../util/logger/logger.module'
import { Module } from '@nestjs/common'
import { MongooseModule } from '@nestjs/mongoose'
import {
  AIGeneratedByTMTag,
  AIGeneratedByTMTagSchema
} from './models/ai-generated-by-tm-tag.schema'
import { ThemeTag, ThemeTagSchema } from './models/asset-theme-tag.schema'
import { MaterialTag, MaterialTagSchema } from './models/material-tag.schema'
import { Tag, TagSchema } from './models/tag.schema'
import {
  ThirdPartySourceTag,
  ThirdPartySourceTagSchema
} from './models/third-party-tag.schema'
import {
  UserGeneratedTag,
  UserGeneratedTagSchema
} from './models/user-generated-tag.schema'
import { TagController } from './tag.controller'
import { TagService } from './tag.service'
import {
  SpaceGenreTag,
  SpaceGenreTagSchema
} from './models/space-genre-tag.schema'

@Module({
  imports: [
    LoggerModule,
    MongooseModule.forFeature([
      {
        name: Tag.name,
        schema: TagSchema,
        discriminators: [
          {
            name: ThemeTag.name,
            schema: ThemeTagSchema
          },
          {
            name: SpaceGenreTag.name,
            schema: SpaceGenreTagSchema
          },
          {
            name: MaterialTag.name,
            schema: MaterialTagSchema
          },
          {
            name: UserGeneratedTag.name,
            schema: UserGeneratedTagSchema
          },
          {
            name: ThirdPartySourceTag.name,
            schema: ThirdPartySourceTagSchema
          },
          {
            name: AIGeneratedByTMTag.name,
            schema: AIGeneratedByTMTagSchema
          }
        ]
      }
    ])
  ],
  controllers: [TagController],
  providers: [TagService],
  exports: [TagService]
})
export class TagModule {}

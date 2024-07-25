import {
  Controller,
  Get,
  Post,
  Body,
  Patch,
  Param,
  Delete,
  UsePipes,
  ValidationPipe,
  UseGuards
} from '@nestjs/common'
import {
  CreateTagDto,
  CreateThirdPartySourceTagDto
} from './dto/create-tag.dto'
import { UpdateTagDto } from './dto/update-tag.dto'
import { TagService } from './tag.service'
import { FirebaseTokenAuthGuard } from '../auth/auth.guard'
import {
  ApiBody,
  ApiCreatedResponse,
  ApiOkResponse,
  ApiOperation,
  ApiParam
} from '@nestjs/swagger'
import { Tag } from './models/tag.schema'
import { ApiResponseProperty } from '@nestjs/swagger/dist/decorators/api-property.decorator'
import { TAG_TYPE } from '../option-sets/tag-type'
import { UserToken } from '../auth/get-user.decorator'
import { DomainOrAuthUserGuard } from '../space/guards/DomainOrAuthUserGuard.guard'

class CreateTagResponse extends Tag {
  @ApiResponseProperty()
  _id: string
}

@UsePipes(new ValidationPipe({ whitelist: false }))
@Controller('tag')
export class TagController {
  constructor(private readonly tagService: TagService) {}

  @Post()
  @FirebaseTokenAuthGuard()
  @ApiBody({
    type: CreateTagDto // 2023-02-13 14:08:07 not sure how to do multiple DTO types at the moment, such just adding parent DTO
  })
  @ApiCreatedResponse({
    type: CreateTagResponse
  })
  public async create(
    @Body() createTagDto: CreateTagDto & CreateThirdPartySourceTagDto,
    @UserToken('user_id') userId: string
  ) {
    // check whether to use the subclass as determined by TAG_TYPE
    switch (createTagDto.tagType) {
      case TAG_TYPE.USER_GENERATED:
        return await this.tagService.createUserGeneratedTag({
          creatorId: userId,
          ...createTagDto
        })
      case TAG_TYPE.THEME:
        return await this.tagService.createThemeTag({
          creatorId: userId,
          ...createTagDto
        })
      case TAG_TYPE.SPACE_GENRE:
        return await this.tagService.createSpaceGenreTag({
          creatorId: userId,
          ...createTagDto
        })
      case TAG_TYPE.MATERIAL:
        return await this.tagService.createMaterialTag({
          creatorId: userId,
          ...createTagDto
        })
      case TAG_TYPE.THIRD_PARTY_SOURCE:
        return await this.tagService.createThirdPartySourceTag({
          creatorId: userId,
          ...createTagDto
        })
      case TAG_TYPE.AI_GENERATED_BY_TM:
        return await this.tagService.createAIGeneratedByTMTag({
          creatorId: userId,
          ...createTagDto
        })

      default: // default to user generated tag
        return await this.tagService.createUserGeneratedTag({
          creatorId: userId,
          ...createTagDto
        })
    }
  }

  @Get('mirror-public-library')
  @UseGuards(DomainOrAuthUserGuard)
  public async findAllMirrorPublicLibraryTags() {
    return await this.tagService.findAllMirrorPublicLibraryTags()
  }

  @Get('theme-tags')
  @UseGuards(DomainOrAuthUserGuard)
  public async findAllThemeTags() {
    return await this.tagService.findAllThemeTags()
  }

  @Get('tag-types')
  @UseGuards(DomainOrAuthUserGuard)
  @ApiOperation({
    summary: 'Get all tag types from the TAG_TYPE enum'
  })
  @ApiOkResponse({ type: [String] })
  public getTagTypes() {
    return this.tagService.getTagTypes()
  }

  @Get(':id')
  @UseGuards(DomainOrAuthUserGuard)
  @ApiParam({ name: 'id', type: 'string', required: true })
  public async findOne(@Param('id') id: string) {
    return await this.tagService.findOne(id)
  }

  @Patch(':id')
  @FirebaseTokenAuthGuard()
  @ApiParam({ name: 'id', type: 'string', required: true })
  public async update(
    @Param('id') id: string,
    @Body() updateAssetDto: UpdateTagDto
  ) {
    return await this.tagService.update(id, updateAssetDto)
  }

  @Delete(':id')
  @FirebaseTokenAuthGuard()
  @ApiParam({ name: 'id', type: 'string', required: true })
  public async remove(@Param('id') id: string) {
    return await this.tagService.remove(id)
  }
}

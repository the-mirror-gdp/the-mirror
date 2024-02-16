import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger'
import {
  IsBoolean,
  IsEmail,
  IsEnum,
  IsMongoId,
  IsNotEmpty,
  IsNumber,
  IsOptional,
  IsString,
  Max,
  Min,
  ValidateIf
} from 'class-validator'
import { USER_AVATAR_TYPE } from '../../option-sets/user-avatar-types'
import {
  ENTITY_TYPE,
  USER_ENTITY_ACTION_TYPE
} from '../models/user-entity-action.schema'
import { ENTITY_TYPE_AVAILABLE_TO_PURCHASE } from '../models/user-cart.schema'

/**
 * NOTE: we don't use full spread operators (...) for DTOs for user because it has senesitive fields that a user shouldn't be able to modify, such as premiumAccess, termsAgreements, etec.
 */
export class UpdateUserProfileDto {
  @IsOptional()
  @IsEmail()
  @ApiPropertyOptional()
  email: string

  @IsOptional()
  @IsString()
  @ApiPropertyOptional()
  displayName: string

  @IsOptional()
  @IsString()
  @ApiPropertyOptional()
  publicBio: string

  @IsOptional()
  @IsString()
  @ApiPropertyOptional()
  discordUserId: string

  @IsOptional()
  @IsString()
  @ApiPropertyOptional()
  polygonPublicKey: string

  @IsOptional()
  @IsString()
  @ApiPropertyOptional()
  ethereumPublicKey: string

  @IsOptional()
  @IsString()
  @ApiPropertyOptional()
  twitterUsername: string

  @IsOptional()
  @IsString()
  @ApiPropertyOptional()
  githubUsername: string

  @IsOptional()
  @IsString()
  @ApiPropertyOptional()
  instagramUsername: string

  @IsOptional()
  @IsString()
  @ApiPropertyOptional()
  youtubeChannel: string

  @IsOptional()
  @IsString()
  @ApiPropertyOptional()
  artStationUsername: string

  @IsOptional()
  @IsString()
  @ApiPropertyOptional()
  sketchfabUsername: string

  @IsOptional()
  @IsString()
  @ApiPropertyOptional()
  profileImage: string

  @IsOptional()
  @IsString()
  @ApiPropertyOptional()
  coverImage: string
}
export class UpdateUserDeepLinkDto {
  @IsString()
  @IsNotEmpty()
  @ApiProperty()
  deepLinkKey: string
  @IsString()
  @IsNotEmpty()
  @ApiProperty()
  deepLinkValue: string
}

export class UpdateUserTermsDto {
  @IsBoolean()
  @IsOptional() // optional so that additional terms can be added to this dto in the future
  @ApiProperty({
    required: false
  })
  termsAgreedtoClosedAlpha?: boolean
  @IsBoolean()
  @IsOptional()
  @ApiProperty({
    required: false
  })
  termsAgreedtoGeneralTOSandPP?: boolean
}

export class UpdateUserAvatarDto {
  @IsString()
  @IsNotEmpty()
  @ApiProperty()
  avatarUrl?: string
}

export class UpdateUserTutorialDto {
  @IsBoolean()
  @IsOptional()
  @ApiProperty()
  shownFirstInSpacePopupV1?: boolean
  @IsBoolean()
  @IsOptional()
  @ApiProperty()
  shownFirstHomeScreenPopupV1?: boolean
  @IsBoolean()
  @IsOptional()
  @ApiProperty()
  shownWebAppPopupV1?: boolean
}

export class UpdateUserAvatarTypeDto {
  @IsEnum(USER_AVATAR_TYPE)
  @IsNotEmpty()
  @ApiProperty()
  avatarType: string

  @ValidateIf((dto) => dto.avatarType === USER_AVATAR_TYPE.READY_PLAYER_ME)
  @IsNotEmpty()
  @ApiProperty()
  readyPlayerMeUrlGlb?: string
}
export class AddRpmAvatarUrlDto {
  @IsString()
  @IsNotEmpty()
  @ApiProperty()
  rpmAvatarUrl: string
}

export class RemoveRpmAvatarUrlDto {
  @IsString()
  @IsNotEmpty()
  @ApiProperty()
  rpmAvatarUrl: string
}

export class UpsertUserEntityActionDto {
  @IsString()
  @IsNotEmpty()
  @ApiProperty()
  forEntity: string

  @IsEnum(USER_ENTITY_ACTION_TYPE)
  @IsNotEmpty()
  @ApiProperty()
  actionType: string

  @IsEnum(ENTITY_TYPE)
  @IsNotEmpty()
  @ApiProperty()
  entityType: string

  /**
   * Optional properties
   */
  @IsNumber()
  @IsOptional()
  @Min(1, { message: 'Minimum rating is 1' })
  @Max(5, { message: 'Maximum rating is 5' })
  @ApiProperty()
  rating?: number
}

export class AddUserCartItemToUserCartDto {
  @IsNotEmpty()
  @IsString()
  @ApiProperty({
    description:
      'The ID of the entity.purchaseOptions array. This is used to track it as the source of truth (e.g. in case the owner changes the purchaseOptions before the buyer pays'
  })
  purchaseOptionId: string

  @IsNotEmpty()
  @IsMongoId()
  @ApiProperty({
    description: "ObjectId of the entity that it's for"
  })
  forEntity: string

  @IsNotEmpty()
  @IsString()
  @IsEnum(ENTITY_TYPE_AVAILABLE_TO_PURCHASE)
  @ApiProperty()
  entityType: string
}

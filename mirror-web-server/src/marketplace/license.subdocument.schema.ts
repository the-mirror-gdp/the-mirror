import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose'
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger'
import { IsOptional, IsString } from 'class-validator'
import mongoose from 'mongoose'
import { ENTITY_TYPE_AVAILABLE_TO_PURCHASE } from '../user/models/user-cart.schema'

export type LicenseDocument = License & Document

/**
 * @description See https://creativecommons.org/about/cclicenses/ and license dropdown list on https://sketchfab.com/3d-models/popular
 */
export enum LICENSE_TYPE {
  // 2023-08-09 17:13:47 To start, we'll just do MIRROR_REV_SHARE, CC0, CC_BY, and ALL_RIGHTS (ALL_RIGHTS is the default for someone who uploads an asset themselves)
  // Creators have full access to an asset with MIRROR_REV_SHARE. This is JUST to note that PLAYERS are restricted from PLAYING games that have assets with MIRROR_REV_SHARE unless they are a Mirror Premium subscriber. When a premium player plays a game with revshare assets, creators of the space get paid out of the pool (both the game creator and the creator of the assets)
  MIRROR_REV_SHARE = 'MIRROR_REV_SHARE',

  /**
   * Very limited, time-duration license so someone building a Space can TRY it before they buy it.
   * Restrictions:
   * - Only Build mode
   * - tryTimeDuration: default 15 minutes
   */
  TRY = 'TRY',

  // Creative Commons
  CC0 = 'CC0', // Full use: public domain
  CC_BY = 'CC_BY', // Full use but author must be credited
  CC_BY_SA = 'CC_BY_SA', // Full use but author must be credited AND modified versions must be shared under the same license

  ALL_RIGHTS = 'ALL_RIGHTS', // default when someone creates a new asset.

  // Important: These are NOT resellable and NOT transferable in the current implementation since we would have to check the license of the original seller. In the future, we could expand this to EXTERNAL_ONE_TIME_PURCHASE_TRANFERABLE though.
  EXTERNAL_ONE_TIME_PURCHASE = 'EXTERNAL_ONE_TIME_PURCHASE', // e.g. a Sketchfab model that is for sale on Sketchfab
  EXTERNAL_SUBSCRIPTION = 'EXTERNAL_SUBSCRIPTION', // e.g. a Sketchfab model that is for sale on Sketchfab

  // One-time purchase from The Mirror. This  Mirrors the Unity standard, Sketchfab standard, etc. Includes usage in Godot and others.
  STANDARD_ONE_TIME_PURCHASE = 'STANDARD_ONE_TIME_PURCHASE',

  // Subscription for a specific item that gets paid to the seller (different than MIRROR_REV_SHARE: this only gives access to the single item). TM takes a commission.
  // Note that we probably WON'T use this for awhile. We may want to approve developers who offer this (e.g. a business that has a plugin that they maintain)
  SUBSCRIPTION_MONTHLY = 'SUBSCRIPTION_MONTHLY'
}

@Schema({
  timestamps: true,
  toJSON: {
    virtuals: true
  }
})
export class License {
  @Prop({
    required: true,
    enum: LICENSE_TYPE
  })
  @ApiProperty({
    enum: LICENSE_TYPE,
    required: true
  })
  licenseType: string

  @Prop({
    required: false,
    enum: ENTITY_TYPE_AVAILABLE_TO_PURCHASE
  })
  @ApiProperty({ type: 'string' })
  entityType?: string

  /**
   * Optional: mainly used if the asset is publicly available and we link to the license (common for CC_BY, CC_BY_SA, etc.)
   * Example: We include these in our public open-source licenses page: https://the-mirror.notion.site/Open-Source-License-Credits-External-Page-8a3e0d75682b48d7bfaa3518f4b5caaf
   *
   * Godot: https://docs.godotengine.org/en/stable/about/complying_with_licenses.html
   * React: https://github.com/facebook/react/raw/master/LICENSE
   */
  @Prop({
    required: false,
    type: String
  })
  @ApiProperty({
    type: String
  })
  urlToLicense?: string

  /**
   * Optional: mainly used if the license was purchased
   */
  @Prop({
    required: false,
    type: Date
  })
  @ApiProperty({
    description:
      'Used to record when the license was purchased (if it was purchased)'
  })
  purchaseDate?: Date

  @Prop({
    required: false,
    type: mongoose.Types.ObjectId,
    refPath: 'entityType'
  })
  @ApiProperty({
    type: 'string',
    description:
      'This references the original entity ID (e.g. the Asset) that the license was originally for. This would be optional if the asset was initially made by the creator himself/herself'
  })
  originalEntityIdIfTransferred?: mongoose.Types.ObjectId

  // Only for LICENSE_TYPE.TRY
  @Prop({
    required: false,
    type: Date
  })
  @ApiProperty({
    type: Date
  })
  tryTimeDuration?: Date

  /**
   * EXTERNAL license fields
   */
  @Prop({
    required: false
  })
  @ApiProperty({
    required: false,
    description:
      'The issuer of the license, such as Sketchfab, Endemic Sound, Unity Asset Store, etc.'
  })
  externalLicenseIssuer?: string

  @Prop({
    required: false
  })
  @ApiProperty({
    required: false,
    description: "The name of the external license, e.g. 'Standard'"
  })
  externalLicenseName?: string

  @Prop({
    required: false
  })
  @ApiProperty({
    required: false,
    description:
      "A URL to the external license, e.g. 'https://sketchfab.com/licenses/standard'"
  })
  externalLicenseUrl?: string

  // TODO: add this when we add Stripe
  // stripeTransactionId? []

  /**
   * Used for subscription licenses
   */
  // TODO add these: TBD.
  /**
   * Timestamp when the subscription validity was last checked - cron job?
   */
}

export const LicenseSchema = SchemaFactory.createForClass(License)

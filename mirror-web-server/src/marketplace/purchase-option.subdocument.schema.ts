import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose'
import { ApiProperty } from '@nestjs/swagger'
import * as mongoose from 'mongoose'
import { LICENSE_TYPE } from './license.subdocument.schema'

export enum CURRENCY_FOR_PURCHASE_OPTION {
  USD = 'usd'
  // EUR = 'eur' // commented out for now
}
/**
 * @description MIRROR_REV_SHARE is for the Mirror Premium Access subscription, similar to Spotify, where the PLAYER pays TM a monthly fee and then TM gives the creator a cut if the user uses that.
 * @date 2023-07-09 17:49
 */
export enum PURCHASE_OPTION_TYPE {
  ONE_TIME = 'ONE_TIME',
  /**
   * IMPORTANT:
   * Spotify model: Charge the players, empower the creators (i.e. we don't charge the creators). Asset creators get paid monthly based on how much their assets are used.
   * Player: When a PLAYER has a Mirror Premium subscription, they can access games that use RevShare assets. The creators (both of the game and the assets) are paid monthly out of the pool of Mirror Premium subscription revenue.
   * Creator: no change, they can use these assets for FREE. They are paid monthly out of the pool of Mirror Premium subscription revenue when paying players play games that have these assets.
   * (Note: If a Space has no RevShare assets, then players can play the game without a premium subscription. If a Space has RevShare assets, then players must have a Mirror Premium subscription to play the game (OR they're shown ads or something else. This is to be determined)
   */
  MIRROR_REV_SHARE = 'MIRROR_REV_SHARE',

  SUBSCRIPTION_MONTHLY = 'SUBSCRIPTION_MONTHLY' // the creator is paid monthly. The Mirror takes a cut. We're not doing this right away.
}

/**
 * This replaces AssetListing
 */
export type PurchaseOptionDocument = PurchaseOption & Document

/**
 * This replaces AssetListing and should only be used a SUBdocument ARRAY of something that can be sold, e.g. asset.purchaseOptions?: PurchaseOption[]
 */
@Schema({
  timestamps: true,
  toJSON: {
    virtuals: true
  }
})
export class PurchaseOption {
  /**
   * Required fields
   */
  @Prop({ required: true, default: false, type: Boolean })
  @ApiProperty({
    required: true,
    default: false,
    description: 'Whether this purchase option is active',
    type: Boolean
  })
  enabled: boolean

  @Prop({ required: false, type: Number })
  @ApiProperty({
    required: true,
    description:
      'The price in the currency specified in the SMALLEST unit, e.g. cents for USD. See https://stripe.com/docs/currencies',
    type: Number
  })
  price: number

  @Prop({ required: false, type: String, enum: CURRENCY_FOR_PURCHASE_OPTION })
  @ApiProperty({
    enum: CURRENCY_FOR_PURCHASE_OPTION,
    description: 'The currency used for the Stripe flow',
    type: String
  })
  currency: string

  @Prop({ required: true, type: 'string', enum: PURCHASE_OPTION_TYPE })
  @ApiProperty({
    enum: PURCHASE_OPTION_TYPE,
    description:
      'One-time purchase, subscription, available with Mirror RevShare, etc.',
    type: String
  })
  type: string

  @Prop({ required: true, type: 'string', enum: LICENSE_TYPE })
  @ApiProperty({
    enum: LICENSE_TYPE,
    description:
      'The license for the purchase: Standard, Mirror RevShare subscription, CC0, etc. Note that on entities like Asset, this is the same enum as asset.license.licenseType',
    type: String
  })
  licenseType: string

  /**
   * Optional fields
   */
  @Prop({
    required: false
  })
  @ApiProperty({ required: false, type: String })
  description: string

  @Prop({ required: false, type: Date })
  @ApiProperty({ required: false })
  startDate: Date

  @Prop({ required: false, type: Date })
  @ApiProperty({ required: false })
  endDate: Date

  _id: mongoose.Types.ObjectId
}

/**
 * This replaces AssetListing
 */
export const PurchaseOptionSchema = SchemaFactory.createForClass(PurchaseOption)

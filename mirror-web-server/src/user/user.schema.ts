import { PREMIUM_ACCESS } from './../option-sets/premium-tiers'
import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose'
import * as mongoose from 'mongoose'
import { Document, SchemaTypes } from 'mongoose'
import { UserGroupInvite } from '../user-groups/user-group-invite.schema'
import { ApiProperty } from '@nestjs/swagger'
import { USER_AVATAR_TYPE } from '../option-sets/user-avatar-types'
import { CustomData } from '../custom-data/models/custom-data.schema'
import { UserCartItem, UserCartItemSchema } from './models/user-cart.schema'
import { UserRecents, UserRecentsSchema } from './models/user-recents.schema'
import {
  UserMarketing,
  UserMarketingSchema
} from './models/user-marketing.schema'

export type UserDocument = User & Document

export const USER_VIRTUAL_PROPERTY_PUBLIC_ASSETS = 'publicAssets'
export const USER_VIRTUAL_PROPERTY_PUBLIC_GROUPS = 'publicGroups'

/**
 * Tutorial nested object. The generic approach is for all of these to be undefined. In the consuming app, check for truthiness of user.tutorial[propertyName], e.g. user.tutorial.shownFirstSpacePopupV1
 */
@Schema()
export class UserTutorial {
  // be sure to keep UpdateUserTutorialDto up to date with these properties
  @Prop({ type: Boolean })
  shownFirstInSpacePopupV1?: boolean
  @Prop({ type: Boolean })
  shownFirstHomeScreenPopupV1?: boolean
  @Prop({ type: Boolean })
  shownWebAppPopupV1?: boolean
}

// Properties must not be undefined so that getPublicPropertiesForMongooseQuery can work
export class UserPublicData {
  @ApiProperty({ type: 'string' }) // @ApiProperty must be included to be exposed by the API and flow to FE codegen
  _id = '' // Must not be undefined
  @ApiProperty({ type: Date })
  createdAt = new Date()
  @ApiProperty({ type: Date })
  updatedAt = new Date()
  @ApiProperty({ type: 'string' })
  discordUserId? = ''
  @ApiProperty({ type: 'string' })
  isInternalAdmin = ''
  @ApiProperty({ type: 'string' })
  displayName = ''
  @ApiProperty({ type: 'string' })
  email = ''
  @ApiProperty({ type: 'string' })
  publicBio = ''
  // We only need a string to decipher the current avatar.
  @ApiProperty({ type: 'string' })
  avatarUrl = ''

  // TODO: We can probably get rid of avatar type and any variables specific to ready player me.
  @ApiProperty({ enum: USER_AVATAR_TYPE })
  avatarType = ''
  @ApiProperty({ type: 'string' })
  readyPlayerMeUrlGlb? = ''
  @ApiProperty({ type: [String] })
  readyPlayerMeAvatarUrls? = []
  @ApiProperty({ type: 'string' })
  polygonPublicKey? = ''
  @ApiProperty({ type: 'string' })
  ethereumPublicKey? = ''
  @ApiProperty({ type: 'string' })
  twitterUsername? = ''
  @ApiProperty({ type: 'string' })
  githubUsername? = ''
  @ApiProperty({ type: 'string' })
  instagramUsername? = ''
  @ApiProperty({ type: 'string' })
  youtubeChannel? = ''
  @ApiProperty({ type: 'string' })
  artStationUsername? = ''
  @ApiProperty({ type: 'string' })
  sketchfabUsername? = ''
  @ApiProperty({ type: 'string' })
  profileImage? = ''
  @ApiProperty({ type: 'string' })
  coverImage? = ''
  @ApiProperty({ type: [String] })
  sidebarTags? = []

  /**
   * Closed Beta
   */
  @ApiProperty({ type: 'boolean' })
  closedBetaHasClickedInterestedInBeta? = false
  @ApiProperty({ type: 'boolean' })
  closedBetaIsInClosedBeta? = false

  /**
   * Terms
   */
  @ApiProperty({ type: 'boolean' })
  termsAgreedtoClosedAlpha? = false

  @ApiProperty({ type: 'boolean' })
  termsAgreedtoGeneralTOSandPP? = false

  @ApiProperty({ enum: PREMIUM_ACCESS, isArray: true })
  premiumAccess: PREMIUM_ACCESS[] = []
}

@Schema({
  timestamps: true,
  toJSON: {
    virtuals: true
  }
})
export class User {
  @ApiProperty()
  _id: string
  @ApiProperty()
  createdAt: Date // this is managed by mongoose timestamps: true, but defining it here so types will align
  @ApiProperty()
  updatedAt: Date // this is managed by mongoose timestamps: true, but defining it here so types will align

  @Prop()
  @ApiProperty()
  firebaseUID: string

  /**
   * Whether the user is a Mirror admin, exposing admin functionality. This should ONLY be used if the person works for The Mirror.
   */
  @Prop()
  @ApiProperty()
  isInternalAdmin: string

  @Prop({
    required: true,
    minLength: 3,
    maxLength: 40
  })
  @ApiProperty()
  displayName: string

  @Prop({ type: [mongoose.Schema.Types.ObjectId], ref: 'UserGroupInvite' })
  @ApiProperty()
  groupInvitations: UserGroupInvite[]

  /**
   * @description Note: Change of pattern: NOT using friends: User[] here since we don't want to always populate the friends. We can always add a friends getter if we want to populate them. I think this will be easier on type safety
   * @date 2023-06-22 23:42
   */
  @Prop({
    type: [mongoose.Schema.Types.ObjectId],
    ref: 'User',
    select: false,
    default: []
  })
  @ApiProperty({
    description: 'A list of User IDs of friends.'
  })
  friends?: mongoose.Schema.Types.ObjectId[]

  /**
   * @description A list of User IDs of friends.
   * Note: Change of pattern: NOT using friends: User[] here since we don't want to always populate the friends. We can always add a friends getter if we want to populate them. I think this will be easier on type safety
   * @date 2023-06-22 23:42
   */
  @Prop({
    type: [mongoose.Schema.Types.ObjectId],
    ref: 'User',
    select: false,
    default: []
  })
  @ApiProperty({
    description: 'A list of User IDs that this User has sent friend requests to'
  })
  sentFriendRequestsToUsers?: mongoose.Schema.Types.ObjectId[]

  @Prop({
    required: false,
    type: UserRecentsSchema
  })
  @ApiProperty()
  recents?: UserRecents

  @Prop({
    required: false,
    type: UserMarketingSchema,
    select: false
  })
  @ApiProperty()
  marketing?: UserMarketing

  @Prop({
    required: false
  })
  @ApiProperty()
  email: string

  @Prop(SchemaTypes.Boolean)
  @ApiProperty()
  emailVerified: boolean

  @Prop()
  @ApiProperty()
  publicBio: string

  // We only need a string to decipher the current avatar.
  @Prop()
  @ApiProperty()
  avatarUrl: string

  // TODO: We can probably get rid of avatar type and any variables specific to ready player me.
  /**
   * The high-level currently selected character (e.g. between a Mirror avatar, Ready Player Me avatar, or something else).
   * ex: If USER_AVATAR_TYPE.READY_PLAYER_ME is selected, then the readyPlayerMeUrlGlb should be used
   */
  @Prop({
    required: true,
    enum: USER_AVATAR_TYPE,
    default: USER_AVATAR_TYPE.MIRROR_AVATAR_V1,
    type: String
  })
  @ApiProperty({ enum: USER_AVATAR_TYPE })
  avatarType: string

  /**
   * @description I was previously adding this as an array, but it became super complex with needing to filter through to just find small pieces of data. We can always add support for arrays of CustomData in the future, but it's much simpler for now to 1 CustomData object per entity. Plus, it can have JSON, so array data can still be stored - it just won't be an array of CustomData types (rather, it will be an array of what the user specifies: string, numbers, etc. Note that we also want to support references to other entities: this will likely be via CustomDataEntityReference or something similar).
   * @date 2023-03-03 20:11
   */
  @Prop({ type: mongoose.Schema.Types.ObjectId, ref: 'CustomData' })
  @ApiProperty()
  customData: CustomData

  @Prop({
    required: true,
    default: {}
  })
  tutorial: UserTutorial

  /**
   * The current string url ending in .glb
   */
  @Prop()
  @ApiProperty()
  readyPlayerMeUrlGlb?: string

  /**
   * Array of avatar IDs
   */
  @Prop([String])
  @ApiProperty()
  readyPlayerMeAvatarUrls: string[]

  /**
   * Closed Beta
   * @deprecated use premiumAccess
   */
  @Prop({
    default: false
  })
  @ApiProperty()
  closedBetaHasClickedInterestedInBeta?: boolean

  /**
   * @deprecated use premiumAccess
   */
  @Prop({
    default: false
  })
  @ApiProperty()
  closedBetaIsInClosedBeta?: boolean

  /**
   * Terms: Closed Alpha
   * Future properties can start with `terms` as well, such as termsAgreedToOpenAlpha, termsAgreedToGeneralTOS, etc.
   */
  @Prop({
    default: false
  })
  @ApiProperty({
    description: 'Whether the user has agreed to the closed alpha agreement'
  })
  termsAgreedtoClosedAlpha?: boolean

  @Prop({
    default: false
  })
  @ApiProperty({
    description:
      'Whether the user has agreed to the general Terms of Service and Privacy Policy'
  })
  termsAgreedtoGeneralTOSandPP?: boolean

  /**
   * Social
   */
  @Prop()
  @ApiProperty()
  discordUserId?: string

  @Prop()
  @ApiProperty()
  polygonPublicKey?: string

  @Prop()
  @ApiProperty()
  ethereumPublicKey?: string

  @Prop()
  @ApiProperty()
  twitterUsername?: string

  @Prop()
  @ApiProperty()
  githubUsername?: string

  @Prop()
  @ApiProperty()
  instagramUsername?: string

  @Prop()
  @ApiProperty()
  youtubeChannel?: string

  @Prop()
  @ApiProperty()
  artStationUsername?: string

  @Prop()
  @ApiProperty()
  sketchfabUsername?: string

  /**
   * Premium access
   * @description Premium access. Note that users can have MULTIPLE. This is important because we want to continually store whether they were in closed alpha. Plus, even with premium tiers, we'll have some "super premium" users too, enterprise users, etc.
   */
  @Prop({
    type: [String]
    // enum: Object.keys(PREMIUM_ACCESS) // I tried using this here at one point but ran into issues. However, we do want to restrict the strings to enum values, so keeping this comment here.
  })
  @ApiProperty({ enum: PREMIUM_ACCESS })
  premiumAccess: PREMIUM_ACCESS[]

  /**
   * Stripe
   */
  @Prop()
  @ApiProperty()
  stripeCustomerId?: string

  @Prop()
  @ApiProperty()
  stripeAccountId?: string

  /**
   * Deep Linking a key-value pair, e.g. spaceId and 1234-5678-abcd-efgh
   */
  @Prop({
    required: false
  })
  @ApiProperty()
  deepLinkKey?: string

  @Prop({
    required: false
  })
  @ApiProperty()
  deepLinkValue?: string

  @Prop({
    required: false
  })
  @ApiProperty()
  deepLinkLastUpdatedAt?: Date

  /**
   * Profile Images
   */
  @Prop()
  @ApiProperty()
  profileImage?: string

  @Prop()
  @ApiProperty()
  coverImage?: string

  /**
   * Cart
   */
  @Prop({
    type: [UserCartItemSchema],
    required: false,
    select: false // note that select is false here so we don't return too many things for user by default
  })
  @ApiProperty({ type: () => UserCartItem })
  cartItems?: UserCartItem[]

  /**
   * Premium Access ID used for subscription handling.
   */

  @Prop()
  @ApiProperty()
  stripeSubscriptionId?: string

  @Prop({ required: false, type: [String] })
  @ApiProperty({ required: false })
  sidebarTags?: string[]

  @Prop({ required: false, type: Date })
  @ApiProperty({ required: false })
  lastActiveTimestamp?: Date

  /**
   * @description When a user requests to delete an account, it is marked with the deleted: true property. A user with the deleted: true property will be filtered out of all search results
   * @date 2023-12-22 17:31
   */

  @Prop({ required: false, type: Boolean })
  @ApiProperty({ required: false })
  deleted?: boolean
}

export const UserSchema = SchemaFactory.createForClass(User)

// Specifying a virtual with a `ref` property is how you enable virtual
// population
UserSchema.virtual(USER_VIRTUAL_PROPERTY_PUBLIC_ASSETS, {
  ref: 'Asset',
  localField: '_id',
  foreignField: 'owner'
})

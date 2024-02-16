import { ObjectId } from 'mongodb'
import { PREMIUM_ACCESS } from '../../src/option-sets/premium-tiers'
import { USER_AVATAR_TYPE } from '../../src/option-sets/user-avatar-types'
import { User } from '../../src/user/user.schema'
import { ModelStub } from './model.stub'

export class UserModelStub extends ModelStub {}
export class UserAccessKeyStub extends ModelStub {}
export class UserEntityActionModelStub extends ModelStub {}

type OverrideProperties = 'creator' | 'customData' | '_id'
export interface IUserWithStringIds extends Omit<User, OverrideProperties> {
  customData?: string
  _id: ObjectId
  createdAt: Date
  updatedAt: Date
}

export const defaultCustomData0ForUsers = {
  _id: '64502f828903ef33d509994c',
  data: {},
  createdAt: '2023-04-14T15:27:41.416Z',
  updatedAt: '2023-04-14T15:27:42.416Z'
}

/**
 * mock user 0
 */
export const mockUser0: IUserWithStringIds = {
  _id: new ObjectId('64503147d14b6c7d37fbdc5a'),
  createdAt: new Date(),
  updatedAt: new Date(),
  firebaseUID: '64503147d14b6c7d37fbdc5a',
  isInternalAdmin: 'mockInternalAdmin',
  displayName: 'Mock User',
  groupInvitations: [],
  email: 'engineering+mockuser0@themirror.space',
  emailVerified: false,
  publicBio: 'Mock bio',
  avatarUrl: 'mockAvatarUrl',
  avatarType: USER_AVATAR_TYPE.MIRROR_AVATAR_V1,
  customData: defaultCustomData0ForUsers._id,
  readyPlayerMeUrlGlb: 'mockReadyPlayerMeUrlGlb',
  readyPlayerMeAvatarUrls: ['mockAvatarUrl1', 'mockAvatarUrl2'],
  closedBetaHasClickedInterestedInBeta: false,
  closedBetaIsInClosedBeta: false,
  termsAgreedtoClosedAlpha: false,
  termsAgreedtoGeneralTOSandPP: false,
  discordUserId: 'mockDiscordUserId',
  polygonPublicKey: 'mockPolygonPublicKey',
  ethereumPublicKey: 'mockEthereumPublicKey',
  twitterUsername: 'mockTwitterUsername',
  githubUsername: 'mockGithubUsername',
  instagramUsername: 'mockInstagramUsername',
  youtubeChannel: 'mockYoutubeChannel',
  artStationUsername: 'mockArtStationUsername',
  premiumAccess: [PREMIUM_ACCESS.CLOSED_ALPHA],
  stripeCustomerId: 'mockStripeCustomerId',
  stripeAccountId: 'mockStripeAccountId',
  deepLinkKey: 'mockDeepLinkKey',
  deepLinkValue: 'mockDeepLinkValue',
  deepLinkLastUpdatedAt: new Date(),
  profileImage: 'mockProfileImageUrl',
  coverImage: 'mockCoverImageUrl',
  tutorial: {}
}

/**
 * mock user 1 owner of zone
 */
export const mockUser1OwnerOfZone: IUserWithStringIds = {
  _id: new ObjectId('645033ac85cd61a72292b3c6'),
  createdAt: new Date(),
  updatedAt: new Date(),
  firebaseUID: '645033ac85cd61a72292b3c6',
  isInternalAdmin: 'mockInternalAdmin',
  displayName: 'Mock User',
  groupInvitations: [],
  email: 'engineering+mockuser1@themirror.space',
  emailVerified: false,
  publicBio: 'Mock bio',
  avatarUrl: 'mockAvatarUrl',
  avatarType: USER_AVATAR_TYPE.MIRROR_AVATAR_V1,
  customData: defaultCustomData0ForUsers._id,
  readyPlayerMeUrlGlb: 'mockReadyPlayerMeUrlGlb',
  readyPlayerMeAvatarUrls: ['mockAvatarUrl1', 'mockAvatarUrl2'],
  closedBetaHasClickedInterestedInBeta: false,
  closedBetaIsInClosedBeta: false,
  termsAgreedtoClosedAlpha: false,
  termsAgreedtoGeneralTOSandPP: false,
  discordUserId: 'mockDiscordUserId',
  polygonPublicKey: 'mockPolygonPublicKey',
  ethereumPublicKey: 'mockEthereumPublicKey',
  twitterUsername: 'mockTwitterUsername',
  githubUsername: 'mockGithubUsername',
  instagramUsername: 'mockInstagramUsername',
  youtubeChannel: 'mockYoutubeChannel',
  artStationUsername: 'mockArtStationUsername',
  premiumAccess: [PREMIUM_ACCESS.CLOSED_ALPHA],
  stripeCustomerId: 'mockStripeCustomerId',
  stripeAccountId: 'mockStripeAccountId',
  deepLinkKey: 'mockDeepLinkKey',
  deepLinkValue: 'mockDeepLinkValue',
  deepLinkLastUpdatedAt: new Date(),
  profileImage: 'mockProfileImageUrl',
  coverImage: 'mockCoverImageUrl',
  tutorial: {}
}

import { ObjectId } from 'mongodb'
import { SPACE_TYPE } from '../../src/option-sets/space'
import { SPACE_TEMPLATE } from '../../src/option-sets/space-templates'
import { ROLE } from '../../src/roles/models/role.enum'
import { Role, userIsOwnerCheck } from '../../src/roles/models/role.schema'
import { CreateSpaceDto } from '../../src/space/dto/create-space.dto'
import { Space } from '../../src/space/space.schema'
import { ModelStub } from './model.stub'
import {
  space20WithActiveSpaceVersionId,
  spaceVersion2ForSpaceWithActiveSpaceVersionId
} from './play-space.stub'
import {
  roleStubDefaultContributor,
  roleStubDefaultDiscover,
  roleStubDefaultManager,
  roleStubDefaultNoRole,
  roleStubDefaultObserver,
  roleStubDefaultOwner
} from './role.model.stub'

// Util: mongo object ID generator: https://observablehq.com/@hugodf/mongodb-objectid-generator

export class SpaceModelStub extends ModelStub {}
type OverrideProperties =
  | 'creator'
  | 'createdAt'
  | 'updatedAt'
  | 'customData'
  | 'spaceVariablesData'
  | 'activeSpaceVersion'
  | 'environment'
  | 'terrain'
  | 'environment'
// 2023-04-19 23:51:57 this isn't fully used in this test file yet since I'm adding this pattern while working on SpaceObject E2E tests, but these tests should be updated to use this interface for the JSON
export interface ISpaceWithStringIds extends Omit<Space, OverrideProperties> {
  creator: string
  environment: string
  terrain: string
  customData: string
  spaceVariablesData: string
  activeSpaceVersion?: ObjectId
  createdAt: string
  updatedAt: string
}
export const defaultCustomData0ForSpacesId = '6430531d21206020088e642e'
export const defaultCustomData0ForSpaces = {
  _id: defaultCustomData0ForSpacesId,
  data: {},
  createdAt: '2023-03-14T15:27:41.416Z',
  updatedAt: '2023-03-14T15:27:42.416Z'
}
export const defaultSpaceVariablesDataDocument0IdForSpaces =
  '647e444e2b3d9033910f146b'
export const defaultSpaceVariablesDataDocument0ForSpaces = {
  _id: defaultSpaceVariablesDataDocument0IdForSpaces,
  data: {},
  createdAt: '2023-05-14T15:27:41.416Z',
  updatedAt: '2023-05-14T15:27:42.416Z'
}

/**
 * Space 1, Private, Individual Owned
 */
export const privateSpaceId1IndividualOwned = '64096a873e145a49d54aff4a'
export const roleIdForPrivateSpace1IndividualOwned = '642281ab4ee6d5ccf2b3c998'
export const privateSpaceOwnerUserAId = '64096abbc20511dca905e714'
export const terrainId = '64096ca15a08c1f2310c813e'
export const environmentId = '64096cade9944520ac96701a'
export const roleForPrivateSpaceIndividualOwned: Role = {
  _id: roleIdForPrivateSpace1IndividualOwned,
  defaultRole: ROLE.NO_ROLE,
  creator: privateSpaceOwnerUserAId as any,
  users: new Map(),
  userGroups: new Map(),
  userIsOwner: userIsOwnerCheck
}

export const privateSpace1DataIndividualOwned = {
  _id: privateSpaceId1IndividualOwned,
  name: 'privateSpace1DataIndividualOwned',
  role: roleForPrivateSpaceIndividualOwned,
  customData: defaultCustomData0ForSpacesId,
  template: SPACE_TEMPLATE.MARS,
  creator: privateSpaceOwnerUserAId,
  type: SPACE_TYPE.OPEN_WORLD,
  environment: environmentId,
  terrain: terrainId,
  createdAt: '2023-03-14T15:27:41.416Z',
  updatedAt: '2023-03-14T15:27:42.416Z'
}
export const privateSpaceOwnerUser = {
  _id: privateSpaceOwnerUserAId
}

/**
 * End: Space 1, Private, Individual Owned
 */

/**
 * Space 2, Private, Individual Owned with ROLE.OBSERVER for User O
 */

export const privateSpaceId2IndividualOwnedWithObserverRoleForUser =
  '642650845f157c12ef646517'
export const roleIdForPrivateSpace2IndividualOwnedWithObserverRoleForUser =
  '642650cc8c4d25962b1c8de7'
export const userOIdWithObserverRoleForSpace2 = '642651066fa849031511a579'
export const privateSpaceData2IndividualOwnedWithObserverRoleForUser = {
  _id: privateSpaceId2IndividualOwnedWithObserverRoleForUser,
  name: 'privateSpaceData2IndividualOwnedWithObserverRoleForUser',
  role: roleForPrivateSpaceIndividualOwned,
  customData: defaultCustomData0ForSpacesId,
  spaceVariablesData: defaultSpaceVariablesDataDocument0ForSpaces._id,
  template: SPACE_TEMPLATE.MARS,
  creator: privateSpaceOwnerUserAId,
  type: SPACE_TYPE.OPEN_WORLD,
  environment: environmentId,
  terrain: terrainId,
  createdAt: '2023-03-14T15:27:41.416Z',
  updatedAt: '2023-03-14T15:27:42.416Z'
}
export const roleForPrivateSpaceIndividualOwnedWithObserverRoleForUser: Role = {
  _id: roleIdForPrivateSpace2IndividualOwnedWithObserverRoleForUser,
  defaultRole: ROLE.NO_ROLE,
  creator: privateSpaceOwnerUserAId as any,
  users: new Map([[userOIdWithObserverRoleForSpace2, ROLE.OBSERVER]]),
  userGroups: new Map(),
  userIsOwner: userIsOwnerCheck
}
/**
 * End: Space 2, Private, Individual Owned
 */

/**
 * Space 3, defaultRole: ROLE.OBSERVER (Public)
 */
export const publicSpace3OwnerUserId = '64096ab9e72eb90fe7cb76d3'
export const roleIdForPublicSpace3 = '6422820a3e73166e51b5e0f6'
export const roleForPublicSpace3: Role = {
  _id: roleIdForPublicSpace3,
  defaultRole: ROLE.OBSERVER,
  creator: publicSpace3OwnerUserId as any,
  users: new Map(),
  userGroups: new Map(),
  userIsOwner: userIsOwnerCheck
}
export const publicSpaceId3 = '64096a9539a1cf03d85d3b09'
export const publicSpace3Data = {
  _id: publicSpaceId3,
  name: 'Public space 3',
  role: roleForPublicSpace3,
  customData: defaultCustomData0ForSpacesId,
  spaceVariablesData: defaultSpaceVariablesDataDocument0ForSpaces._id,
  template: SPACE_TEMPLATE.MARS,
  creator: publicSpace3OwnerUserId,
  type: SPACE_TYPE.OPEN_WORLD,
  environment: environmentId,
  terrain: terrainId,
  createdAt: new Date().toISOString(),
  updatedAt: new Date().toISOString()
}
export const publicSpace3OwnerUserC = {
  _id: publicSpace3OwnerUserId
}

/**
 * End Space 3, defaultRole: ROLE.OBSERVER (Public)
 */

/**
 * Space 4, Private, Group Owned
 */
export const privateSpaceId4GroupOwned = '6413624b6d9e0c799650d6a3'
export const roleIdForPrivateSpace4GroupOwned = '642282c6b7405b2d9efb47b5'
/**
 * @description I know this is wordy, but this is a USER ID that is an OWNER in a USERGROUP that OWNS a SPACE that IS groupOwned==true. So thus, an owner by way of being an owner of the group that owns the Space.
 */
export const privateSpacer4UserDIdOwnerInOwnerUserGroup =
  '6424fb70a3b9a59a7d61247f'
/**
 * @description a USERGROUP ID that OWNS a private space that is groupOwned==true
 */
export const privateSpace4OwnerUserGroupId = '641363309ef8962d32507af4'
export const roleForPrivateSpace4GroupOwned: Role = {
  _id: roleIdForPrivateSpace4GroupOwned,
  defaultRole: ROLE.NO_ROLE,
  creator: privateSpaceOwnerUserAId as any,
  users: new Map(),
  userGroups: new Map(),
  userIsOwner: userIsOwnerCheck
}
export const privateSpace4DataGroupOwned = {
  _id: privateSpaceId4GroupOwned,
  name: 'privateSpace4DataGroupOwned',
  role: roleForPrivateSpace4GroupOwned,
  customData: defaultCustomData0ForSpacesId,
  spaceVariablesData: defaultSpaceVariablesDataDocument0ForSpaces._id,
  template: SPACE_TEMPLATE.MARS,
  creator: privateSpaceOwnerUserAId, //intentionally not Space 4/User D so that we check if groupOwned logic is respected
  type: SPACE_TYPE.OPEN_WORLD,
  environment: environmentId,
  terrain: terrainId,
  createdAt: '2023-03-14T15:27:41.416Z',
  updatedAt: '2023-03-14T15:27:42.416Z'
}

export const privateSpace4OwnerUserGroup = {
  _id: privateSpace4OwnerUserGroupId,
  owners: [privateSpacer4UserDIdOwnerInOwnerUserGroup]
}
/**
 * End: Space 4, Private, Group Owned
 */

export const environmentData = {
  _id: environmentId,
  id: environmentId,
  skyTopColor: [0.38, 0.45, 0.55],
  skyHorizonColor: [0.65, 0.65, 0.67],
  skyBottomColor: [0.2, 0.17, 0.13],
  sunCount: 1,
  suns: [],
  fogEnabled: false,
  fogVolumetric: true,
  fogDensity: 0.01,
  fogColor: [0.8, 0.9, 1],
  globalIllumination: false,
  createdAt: '2023-03-14T15:27:41.416Z',
  updatedAt: '2023-03-14T15:27:42.416Z',
  __v: 0
}

/**
 * Space 6
 */
export const space6ToBeCreatedPrivateIndividualOwnerWithObserverUser: CreateSpaceDto =
  {
    name: 'space6ToBeCreatedPrivateIndividualOwnerWithObserverUser',
    public: false,
    template: SPACE_TEMPLATE.MARS,
    type: SPACE_TYPE.OPEN_WORLD
    // createdAt and updatedAt should be populated by Mongoose
  }

/**
 * Space 7
 */
export const space7ToBeCreatedPrivateIndividualOwner: CreateSpaceDto = {
  name: 'space7ToBeCreatedPrivateIndividualOwner',
  public: false,
  template: SPACE_TEMPLATE.MARS,
  type: SPACE_TYPE.OPEN_WORLD,
  users: {} // will be set during test
  // createdAt and updatedAt should be populated by Mongoose
}

/**
 * Space 8
 */
export const space8ToBeCreatedPrivateUserGroupOwnedWIP: CreateSpaceDto = {
  // TODO: add the userGroup its owned by
  name: 'space8ToBeCreatedPrivateUserGroupOwnedWIP',
  public: false,
  template: SPACE_TEMPLATE.MARS,
  type: SPACE_TYPE.OPEN_WORLD
  // createdAt and updatedAt should be populated by Mongoose
}

/**
 * Space 9
 */
export const space9ToBeCreatedPublic: CreateSpaceDto = {
  name: 'space9ToBeCreatedPublic',
  public: true,
  template: SPACE_TEMPLATE.MARS,
  type: SPACE_TYPE.OPEN_WORLD
  // createdAt and updatedAt should be populated by Mongoose
}

// Adding these for better usage of role stub file

/**
 * Space 10 with ROLE.MANAGER defaultRole
 */
export const space10WithManagerDefaultRole: ISpaceWithStringIds = {
  _id: '60f9d55b1234567890123470',
  role: roleStubDefaultManager,
  name: 'Test Space',
  description: 'A test space for demonstration purposes.',
  images: ['https://example.com/image1.jpg', 'https://example.com/image2.jpg'],
  tags: ['demo', 'test'],
  type: SPACE_TYPE.OPEN_WORLD,
  customData: defaultCustomData0ForSpaces._id,
  spaceVariablesData: defaultSpaceVariablesDataDocument0ForSpaces._id,
  lowerLimitY: -200,
  template: SPACE_TEMPLATE.MARS,
  terrain: '60f9d55b1234567890123472',
  environment: '60f9d55b1234567890123473',
  creator: '60f9d55b1234567890123475',
  createdAt: '2023-04-19T00:00:00.000Z',
  updatedAt: '2023-04-19T00:00:00.000Z'
}

/**
 * Space 11 with ROLE.CONTRIBUTOR defaultRole
 */
export const space11WithContributorDefaultRole: ISpaceWithStringIds = {
  _id: '6440d72e03aac1524fab4273',
  role: roleStubDefaultContributor,
  name: 'Test Space',
  description: 'A test space for demonstration purposes.',
  images: ['https://example.com/image1.jpg', 'https://example.com/image2.jpg'],
  tags: ['demo', 'test'],
  type: SPACE_TYPE.OPEN_WORLD,
  customData: defaultCustomData0ForSpaces._id,
  spaceVariablesData: defaultSpaceVariablesDataDocument0ForSpaces._id,
  lowerLimitY: -200,
  template: SPACE_TEMPLATE.MARS,
  terrain: '60f9d55b1234567890123472',
  environment: '60f9d55b1234567890123473',
  creator: '60f9d55b1234567890123475',
  createdAt: '2023-04-19T00:00:00.000Z',
  updatedAt: '2023-04-19T00:00:00.000Z'
}

/**
 * Space 12 with ROLE.OBSERVER defaultRole
 */
export const space12WithObserverDefaultRole: ISpaceWithStringIds = {
  _id: '6440d721f4fcf914087ac8b8',
  role: roleStubDefaultObserver,
  name: 'Test Space',
  description: 'A test space for demonstration purposes.',
  images: ['https://example.com/image1.jpg', 'https://example.com/image2.jpg'],
  tags: ['demo', 'test'],
  type: SPACE_TYPE.OPEN_WORLD,
  customData: defaultCustomData0ForSpaces._id,
  spaceVariablesData: defaultSpaceVariablesDataDocument0ForSpaces._id,
  lowerLimitY: -200,
  template: SPACE_TEMPLATE.MARS,
  terrain: '60f9d55b1234567890123472',
  environment: '60f9d55b1234567890123473',
  creator: '60f9d55b1234567890123475',
  createdAt: '2023-04-19T00:00:00.000Z',
  updatedAt: '2023-04-19T00:00:00.000Z'
}

/**
 * Space 13 with ROLE.DISCOVER defaultRole
 */
export const space13WithDiscoverDefaultRole: ISpaceWithStringIds = {
  _id: '6440d71e62c626fea10cfd85',
  role: roleStubDefaultDiscover,
  name: 'Test Space',
  description: 'A test space for demonstration purposes.',
  images: ['https://example.com/image1.jpg', 'https://example.com/image2.jpg'],
  tags: ['demo', 'test'],
  type: SPACE_TYPE.OPEN_WORLD,
  customData: defaultCustomData0ForSpaces._id,
  spaceVariablesData: defaultSpaceVariablesDataDocument0ForSpaces._id,
  lowerLimitY: -200,
  template: SPACE_TEMPLATE.MARS,
  terrain: '60f9d55b1234567890123472',
  environment: '60f9d55b1234567890123473',
  creator: '60f9d55b1234567890123475',
  createdAt: '2023-04-19T00:00:00.000Z',
  updatedAt: '2023-04-19T00:00:00.000Z'
}

/**
 * Space 14 with ROLE.NO_ROLE defaultRole
 */
export const space14WithNoRoleDefaultRole: ISpaceWithStringIds = {
  _id: '6440d71a840a5702ed3e2f09',
  role: roleStubDefaultNoRole,
  name: 'Test Space',
  description: 'A test space for demonstration purposes.',
  images: ['https://example.com/image1.jpg', 'https://example.com/image2.jpg'],
  tags: ['demo', 'test'],
  type: SPACE_TYPE.OPEN_WORLD,
  customData: defaultCustomData0ForSpaces._id,
  spaceVariablesData: defaultSpaceVariablesDataDocument0ForSpaces._id,
  lowerLimitY: -200,
  template: SPACE_TEMPLATE.MARS,
  terrain: '60f9d55b1234567890123472',
  environment: '60f9d55b1234567890123473',
  creator: '60f9d55b1234567890123475',
  createdAt: '2023-04-19T00:00:00.000Z',
  updatedAt: '2023-04-19T00:00:00.000Z'
}

/**
 * Space 15 for SpaceObjects copied TO it
 */
export const space15ForSpaceObjectsCopiedToIt: CreateSpaceDto = {
  name: 'space15ForSpaceObjectsCopiedToIt',
  public: false,
  template: SPACE_TEMPLATE.MARS,
  type: SPACE_TYPE.OPEN_WORLD,
  users: {} // will be set during test
  // createdAt and updatedAt should be populated by Mongoose
}

/**
 * Space 16: Lots created
 */
export const space16ToBeCreatedManyPrivateIndividualOwner: CreateSpaceDto = {
  name: 'space16ToBeCreatedManyPrivateIndividualOwner',
  public: false,
  template: SPACE_TEMPLATE.MARS,
  type: SPACE_TYPE.OPEN_WORLD,
  users: {} // will be set during test
  // createdAt and updatedAt should be populated by Mongoose
}

/**
 * Space 17: For Zone Creation
 */
export const space17ForZoneToBeCreated: ISpaceWithStringIds = {
  _id: '644777db50318568a2e932d5',
  role: roleStubDefaultOwner, // this needs to be owner because it gets published during a test, which requires owner perms
  name: 'space17ForZoneToBeCreated',
  description: 'A test space for demonstration purposes.',
  images: ['https://example.com/image1.jpg', 'https://example.com/image2.jpg'],
  tags: ['demo', 'test'],
  type: SPACE_TYPE.OPEN_WORLD,
  customData: defaultCustomData0ForSpaces._id,
  spaceVariablesData: defaultSpaceVariablesDataDocument0ForSpaces._id,
  lowerLimitY: -200,
  template: SPACE_TEMPLATE.MARS,
  terrain: '60f9d55b1234567890123472',
  environment: '60f9d55b1234567890123473',
  creator: '60f9d55b1234567890123475',
  createdAt: '2023-04-19T00:00:00.000Z',
  updatedAt: '2023-04-19T00:00:00.000Z'
}

/**
 * Space 18: seeded for seeded Zone
 */
export const space18SeededForSeededZone: ISpaceWithStringIds = {
  _id: '645034b18c27ddb1a1da6f2e',
  role: roleStubDefaultContributor,
  name: 'space18SeededForSeededZone',
  description: 'A test space for demonstration purposes.',
  images: ['https://example.com/image1.jpg', 'https://example.com/image2.jpg'],
  tags: ['demo', 'test'],
  type: SPACE_TYPE.OPEN_WORLD,
  customData: defaultCustomData0ForSpaces._id,
  spaceVariablesData: defaultSpaceVariablesDataDocument0ForSpaces._id,
  lowerLimitY: -200,
  template: SPACE_TEMPLATE.MARS,
  terrain: '60f9d55b1234567890123472',
  environment: '60f9d55b1234567890123473',
  creator: '60f9d55b1234567890123475',
  createdAt: '2023-04-19T00:00:00.000Z',
  updatedAt: '2023-04-19T00:00:00.000Z'
}

/**
 * Space 19: For Zone Creation with spaceVersion
 */
export const space19ForZoneToBeCreatedWithSpaceVersion: ISpaceWithStringIds = {
  _id: '6455307a88d1d2d625d600c0',
  role: roleStubDefaultNoRole,
  name: 'space19ForZoneToBeCreatedWithSpaceVersion',
  description: 'A test space for demonstration purposes.',
  images: ['https://example.com/image1.jpg', 'https://example.com/image2.jpg'],
  tags: ['demo', 'test'],
  type: SPACE_TYPE.OPEN_WORLD,
  customData: defaultCustomData0ForSpaces._id,
  spaceVariablesData: defaultCustomData0ForSpaces._id,
  lowerLimitY: -200,
  template: SPACE_TEMPLATE.MARS,
  terrain: '60f9d55b1234567890123472',
  environment: '60f9d55b1234567890123473',
  creator: '60f9d55b1234567890123475',
  createdAt: '2023-04-19T00:00:00.000Z',
  updatedAt: '2023-04-19T00:00:00.000Z'
}

/**
 * Space 20: with activeSpaceVersion
 */
export const space20WithActiveSpaceVersion: ISpaceWithStringIds = {
  _id: space20WithActiveSpaceVersionId,
  role: roleStubDefaultObserver,
  name: 'space20WithActiveSpaceVersion',
  description: 'A test space for demonstration purposes.',
  images: ['https://example.com/image1.jpg', 'https://example.com/image2.jpg'],
  tags: ['demo', 'test'],
  type: SPACE_TYPE.OPEN_WORLD,
  customData: defaultCustomData0ForSpaces._id,
  spaceVariablesData: defaultCustomData0ForSpaces._id,
  lowerLimitY: -200,
  template: SPACE_TEMPLATE.MARS,
  terrain: '60f9d55b1234567890123472',
  environment: '60f9d55b1234567890123473',
  creator: '60f9d55b1234567890123475',
  createdAt: '2023-04-19T00:00:00.000Z',
  updatedAt: '2023-04-19T00:00:00.000Z',
  activeSpaceVersion: new ObjectId(
    spaceVersion2ForSpaceWithActiveSpaceVersionId
  )
}

export const roleForPublicSpace21: Role = {
  _id: roleIdForPublicSpace3,
  defaultRole: ROLE.OBSERVER,
  creator: publicSpace3OwnerUserId as any,
  users: new Map(),
  userGroups: new Map(),
  userIsOwner: userIsOwnerCheck,
  roleLevelRequiredToDuplicate: ROLE.OBSERVER
}
export const publicSpace21Data = {
  _id: '64b0defdfb856c000074e59c',
  name: 'publicSpace21 for copy',
  role: roleForPublicSpace21,
  customData: defaultCustomData0ForSpacesId,
  spaceVariablesData: defaultSpaceVariablesDataDocument0ForSpaces._id,
  template: SPACE_TEMPLATE.MARS,
  creator: publicSpace3OwnerUserId,
  type: SPACE_TYPE.OPEN_WORLD,
  environment: environmentId,
  terrain: terrainId,
  createdAt: new Date().toISOString(),
  updatedAt: new Date().toISOString()
}

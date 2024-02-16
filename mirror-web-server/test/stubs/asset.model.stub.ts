import {
  mockTagAMirrorPublicLibrary,
  mockTagBMirrorPublicLibrary,
  mockTagCMirrorPublicLibraryThirdPartySource
} from './tag.model.stub'
import { CreateAssetDto } from './../../src/asset/dto/create-asset.dto'
import { Asset } from '../../src/asset/asset.schema'
import { ASSET_TYPE } from '../../src/option-sets/asset-type'
import { ModelStub } from './model.stub'
import { UserId } from '../../src/util/mongo-object-id-helpers'
import {
  IRoleWithStringIds,
  roleStubDefaultContributor,
  roleStubDefaultDiscover,
  roleStubDefaultManager,
  roleStubDefaultNoRole,
  roleStubDefaultObserver
} from './role.model.stub'
import { ROLE } from '../../src/roles/models/role.enum'
import { ObjectId } from 'mongodb'

export const assetManagerUserId: UserId = '63d824ca169f17bd92617b57' // this ID is used everywhere from our engineering+assetmanager@themirror.space account

export class AssetModelStub extends ModelStub {}

type OverrideProperties =
  | 'creator'
  | 'owner'
  | 'asset'
  | 'customData'
  | 'space'
  | 'tagsV2'
  | 'createdAt'
  | 'updatedAt'
  | 'role'
export interface IAssetWithIds extends Omit<Asset, OverrideProperties> {
  creator: string
  customData: string
  tagsV2: ObjectId[]
  createdAt: string
  updatedAt: string
  role: IRoleWithStringIds
}
export interface ICreateAssetDtoWithIds
  extends Omit<CreateAssetDto, OverrideProperties> {
  tagsV2: ObjectId[]
}

export const asset500: IAssetWithIds = {
  _id: '507f1f77bcf86cd799439011',
  role: roleStubDefaultObserver,
  createdAt: '2023-04-19T10:00:00.000Z',
  updatedAt: '2023-04-19T11:00:00.000Z',
  name: 'Test Asset',
  assetType: ASSET_TYPE.MESH,
  description: 'A test asset for unit testing.',
  mirrorPublicLibrary: false,
  customData: '507f191e810c19729de860ea',
  creator: '507f1f77bcf86cd799439014',
  public: true,
  thumbnail: 'test-thumbnail.jpg',
  tags: ['tag1', 'tag2'],
  tagsV2: [mockTagAMirrorPublicLibrary._id, mockTagBMirrorPublicLibrary._id],
  currentFile: 'test-file.jpg',
  initPositionX: 0,
  initPositionY: 0,
  initPositionZ: 0,
  initRotationX: 0,
  initRotationY: 0,
  initRotationZ: 0,
  initScaleX: 1,
  initScaleY: 1,
  initScaleZ: 1,
  collisionEnabled: true,
  staticEnabled: true,
  massKg: 1.0,
  gravityScale: 1.0,
  objectColor: [1.0, 1.0, 1.0, 1.0]
}

export const materialAsset501: IAssetWithIds = {
  _id: '6440b560332e488b4d15523a',
  role: roleStubDefaultObserver,
  createdAt: '2023-04-19T10:00:00.000Z',
  updatedAt: '2023-04-19T11:00:00.000Z',
  name: 'Test Material Asset',
  assetType: ASSET_TYPE.MATERIAL,
  description: 'A test asset material for automated testing.',
  mirrorPublicLibrary: false,
  customData: '6440b57116432aea8466ac58',
  creator: '6440b578f73a1296b5e0af50',
  public: true,
  thumbnail: 'test-thumbnail.jpg',
  tags: ['tag1', 'tag2'],
  tagsV2: [mockTagAMirrorPublicLibrary._id, mockTagBMirrorPublicLibrary._id],
  currentFile: 'test-file.jpg',
  initPositionX: 0,
  initPositionY: 0,
  initPositionZ: 0,
  initRotationX: 0,
  initRotationY: 0,
  initRotationZ: 0,
  initScaleX: 1,
  initScaleY: 1,
  initScaleZ: 1,
  collisionEnabled: true,
  staticEnabled: true,
  massKg: 1.0,
  gravityScale: 1.0,
  objectColor: [1.0, 1.0, 1.0, 1.0]
}

export const asset502ToBeCreated: ICreateAssetDtoWithIds = {
  defaultRole: ROLE.NO_ROLE,
  name: 'asset502ToBeCreated',
  assetType: ASSET_TYPE.MESH,
  description: 'A test asset for E2E testing.',
  mirrorPublicLibrary: false,
  public: false,
  thumbnail: 'test-thumbnail.jpg',
  tags: ['tag1', 'tag2'],
  tagsV2: [mockTagAMirrorPublicLibrary._id, mockTagBMirrorPublicLibrary._id],
  currentFile: 'test-file.jpg',
  initPositionX: 0,
  initPositionY: 0,
  initPositionZ: 0,
  initRotationX: 0,
  initRotationY: 0,
  initRotationZ: 0,
  initScaleX: 1,
  initScaleY: 1,
  initScaleZ: 1,
  collisionEnabled: true,
  staticEnabled: true,
  massKg: 1.0,
  gravityScale: 1.0,
  objectColor: [1.0, 1.0, 1.0, 1.0]
}

export const asset503ToBeCreated: ICreateAssetDtoWithIds = {
  defaultRole: ROLE.NO_ROLE,
  name: 'asset503ToBeCreated',
  assetType: ASSET_TYPE.MESH,
  description: 'A test asset for E2E testing. asset503ToBeCreated',
  mirrorPublicLibrary: false,
  public: true,
  thumbnail: 'test-thumbnail.jpg',
  tags: ['tag1', 'tag2'],
  tagsV2: [mockTagAMirrorPublicLibrary._id, mockTagBMirrorPublicLibrary._id],
  currentFile: 'test-file.jpg',
  initPositionX: 0,
  initPositionY: 0,
  initPositionZ: 0,
  initRotationX: 0,
  initRotationY: 0,
  initRotationZ: 0,
  initScaleX: 1,
  initScaleY: 1,
  initScaleZ: 1,
  collisionEnabled: true,
  staticEnabled: true,
  massKg: 1.0,
  gravityScale: 1.0,
  objectColor: [1.0, 1.0, 1.0, 1.0]
}

export const asset504ManyToBeCreated: ICreateAssetDtoWithIds = {
  name: 'asset504ManyToBeCreated',
  assetType: ASSET_TYPE.MESH,
  description: 'A test asset for E2E testing. asset504ManyToBeCreated',
  mirrorPublicLibrary: false,
  public: true,
  thumbnail: 'test-thumbnail.jpg',
  tags: ['tag1', 'tag2'],
  tagsV2: [mockTagAMirrorPublicLibrary._id, mockTagBMirrorPublicLibrary._id],
  currentFile: 'test-file.jpg',
  initPositionX: 0,
  initPositionY: 0,
  initPositionZ: 0,
  initRotationX: 0,
  initRotationY: 0,
  initRotationZ: 0,
  initScaleX: 1,
  initScaleY: 1,
  initScaleZ: 1,
  collisionEnabled: true,
  staticEnabled: true,
  massKg: 1.0,
  gravityScale: 1.0,
  objectColor: [1.0, 1.0, 1.0, 1.0]
}

export const asset506Seeded: IAssetWithIds = {
  _id: '645017900041f94543987f9b',
  role: roleStubDefaultObserver,
  createdAt: '2023-04-19T10:00:00.000Z',
  updatedAt: '2023-04-19T11:00:00.000Z',
  name: 'Test Asset asset506Seeded',
  assetType: ASSET_TYPE.MESH,
  description: 'A test asset for testing. asset506Seeded',
  mirrorPublicLibrary: false,
  customData: '507f191e810c19729de860ea',
  creator: '507f1f77bcf86cd799439014',
  public: true,
  thumbnail: 'test-thumbnail.jpg',
  tags: ['tag1', 'tag2'],
  tagsV2: [mockTagAMirrorPublicLibrary._id, mockTagBMirrorPublicLibrary._id],
  currentFile: 'test-file.jpg',
  initPositionX: 0,
  initPositionY: 0,
  initPositionZ: 0,
  initRotationX: 0,
  initRotationY: 0,
  initRotationZ: 0,
  initScaleX: 1,
  initScaleY: 1,
  initScaleZ: 1,
  collisionEnabled: true,
  staticEnabled: true,
  massKg: 1.0,
  gravityScale: 1.0,
  objectColor: [1.0, 1.0, 1.0, 1.0]
}

export const asset507MaterialMirrorPublicLibrarySeeded: IAssetWithIds = {
  _id: '64516fe7af63775b093804dc',
  role: roleStubDefaultObserver,
  createdAt: '2023-04-19T10:00:00.000Z',
  updatedAt: '2023-04-19T11:00:00.000Z',
  name: 'Test Asset asset507MaterialMirrorPublicLibrarySeeded',
  assetType: ASSET_TYPE.MATERIAL,
  description:
    'A test asset for testing. asset507MaterialMirrorPublicLibrarySeeded',
  mirrorPublicLibrary: true,
  customData: '507f191e810c19729de860ea',
  creator: '507f1f77bcf86cd799439014',
  public: true,
  thumbnail: 'test-thumbnail.jpg',
  tags: ['tag1', 'tag2'],
  tagsV2: [mockTagAMirrorPublicLibrary._id, mockTagBMirrorPublicLibrary._id],
  currentFile: 'test-file.jpg',
  initPositionX: 0,
  initPositionY: 0,
  initPositionZ: 0,
  initRotationX: 0,
  initRotationY: 0,
  initRotationZ: 0,
  initScaleX: 1,
  initScaleY: 1,
  initScaleZ: 1,
  collisionEnabled: true,
  staticEnabled: true,
  massKg: 1.0,
  gravityScale: 1.0,
  objectColor: [1.0, 1.0, 1.0, 1.0]
}

export const asset508MaterialMirrorPublicLibraryThirdPartySourceSeeded: IAssetWithIds =
  {
    _id: '6451701ea4281edcf22e61ff',
    role: roleStubDefaultObserver,
    createdAt: '2023-04-19T10:00:00.000Z',
    updatedAt: '2023-04-19T11:00:00.000Z',
    name: 'Test Asset asset508MateralMirrorPublicLibraryThirdPartySourceSeeded',
    assetType: ASSET_TYPE.MATERIAL,
    description:
      'A test asset for testing. asset508MateralMirrorPublicLibraryThirdPartySourceSeeded',
    mirrorPublicLibrary: true,
    customData: '507f191e810c19729de860ea',
    creator: '507f1f77bcf86cd799439014',
    public: true,
    thumbnail: 'test-thumbnail.jpg',
    tags: ['tag1', 'tag2'],
    tagsV2: [
      mockTagAMirrorPublicLibrary._id,
      mockTagBMirrorPublicLibrary._id,
      mockTagCMirrorPublicLibraryThirdPartySource._id
    ],
    currentFile: 'test-file.jpg',
    initPositionX: 0,
    initPositionY: 0,
    initPositionZ: 0,
    initRotationX: 0,
    initRotationY: 0,
    initRotationZ: 0,
    initScaleX: 1,
    initScaleY: 1,
    initScaleZ: 1,
    collisionEnabled: true,
    staticEnabled: true,
    massKg: 1.0,
    gravityScale: 1.0,
    objectColor: [1.0, 1.0, 1.0, 1.0]
  }

export const asset509MeshMirrorPublicLibraryThirdPartySourceSeeded: IAssetWithIds =
  {
    _id: '645176cdb6fb1005a73cd78d',
    role: roleStubDefaultObserver,
    createdAt: '2023-04-19T10:00:00.000Z',
    updatedAt: '2023-04-19T11:00:00.000Z',
    name: 'Test Asset asset509MeshMirrorPublicLibraryThirdPartySourceSeeded',
    assetType: ASSET_TYPE.MESH,
    description:
      'A test asset for testing. asset509MeshMirrorPublicLibraryThirdPartySourceSeeded',
    mirrorPublicLibrary: true,
    customData: '507f191e810c19729de860ea',
    creator: '507f1f77bcf86cd799439014',
    public: true,
    thumbnail: 'test-thumbnail.jpg',
    tags: ['tag1', 'tag2'],
    tagsV2: [
      mockTagAMirrorPublicLibrary._id,
      mockTagBMirrorPublicLibrary._id,
      mockTagCMirrorPublicLibraryThirdPartySource._id
    ],
    currentFile: 'test-file.jpg',
    initPositionX: 0,
    initPositionY: 0,
    initPositionZ: 0,
    initRotationX: 0,
    initRotationY: 0,
    initRotationZ: 0,
    initScaleX: 1,
    initScaleY: 1,
    initScaleZ: 1,
    collisionEnabled: true,
    staticEnabled: true,
    massKg: 1.0,
    gravityScale: 1.0,
    objectColor: [1.0, 1.0, 1.0, 1.0]
  }

/**
 * Asset 10 with ROLE.MANAGER defaultRole
 */
export const asset510WithManagerDefaultRoleSeeded: IAssetWithIds = {
  name: 'Test Asset asset510WithManagerDefaultRoleSeeded',
  _id: '6451d9fdc35557babce9d0dd',
  role: roleStubDefaultManager,
  createdAt: '2023-04-19T10:00:00.000Z',
  updatedAt: '2023-04-19T11:00:00.000Z',
  assetType: ASSET_TYPE.MESH,
  description: 'A test asset for testing',
  mirrorPublicLibrary: true,
  customData: '507f191e810c19729de860ea',
  creator: '507f1f77bcf86cd799439014',
  public: true,
  thumbnail: 'test-thumbnail.jpg',
  tags: ['tag1', 'tag2'],
  tagsV2: [
    mockTagAMirrorPublicLibrary._id,
    mockTagBMirrorPublicLibrary._id,
    mockTagCMirrorPublicLibraryThirdPartySource._id
  ],
  currentFile: 'test-file.jpg',
  initPositionX: 0,
  initPositionY: 0,
  initPositionZ: 0,
  initRotationX: 0,
  initRotationY: 0,
  initRotationZ: 0,
  initScaleX: 1,
  initScaleY: 1,
  initScaleZ: 1,
  collisionEnabled: true,
  staticEnabled: true,
  massKg: 1.0,
  gravityScale: 1.0,
  objectColor: [1.0, 1.0, 1.0, 1.0]
}

/**
 * Asset 11 with ROLE.CONTRIBUTOR defaultRole
 */
export const asset511WithManagerDefaultRoleSeeded: IAssetWithIds = {
  name: 'Test Asset asset511WithManagerDefaultRoleSeeded',
  _id: '6451da2ba943b489842e914a',
  role: roleStubDefaultContributor,
  createdAt: '2023-04-19T10:00:00.000Z',
  updatedAt: '2023-04-19T11:00:00.000Z',
  assetType: ASSET_TYPE.MESH,
  description: 'A test asset for testing',
  mirrorPublicLibrary: true,
  customData: '507f191e810c19729de860ea',
  creator: '507f1f77bcf86cd799439014',
  public: true,
  thumbnail: 'test-thumbnail.jpg',
  tags: ['tag1', 'tag2'],
  tagsV2: [mockTagAMirrorPublicLibrary._id, mockTagBMirrorPublicLibrary._id],
  currentFile: 'test-file.jpg',
  initPositionX: 0,
  initPositionY: 0,
  initPositionZ: 0,
  initRotationX: 0,
  initRotationY: 0,
  initRotationZ: 0,
  initScaleX: 1,
  initScaleY: 1,
  initScaleZ: 1,
  collisionEnabled: true,
  staticEnabled: true,
  massKg: 1.0,
  gravityScale: 1.0,
  objectColor: [1.0, 1.0, 1.0, 1.0]
}

/**
 * Asset 12 with ROLE.OBSERVER defaultRole
 */
export const asset512WithObserverDefaultRoleSeeded: IAssetWithIds = {
  name: 'Test Asset asset512WithObserverDefaultRoleSeeded',
  _id: '6451da7ba2c2ca302e23bbe9',
  role: roleStubDefaultObserver,
  createdAt: '2023-04-19T10:00:00.000Z',
  updatedAt: '2023-04-19T11:00:00.000Z',
  assetType: ASSET_TYPE.MESH,
  description: 'A test asset for testing',
  mirrorPublicLibrary: true,
  customData: '507f191e810c19729de860ea',
  creator: '507f1f77bcf86cd799439014',
  public: true,
  thumbnail: 'test-thumbnail.jpg',
  tags: ['tag1', 'tag2'],
  tagsV2: [mockTagAMirrorPublicLibrary._id, mockTagBMirrorPublicLibrary._id],
  currentFile: 'test-file.jpg',
  initPositionX: 0,
  initPositionY: 0,
  initPositionZ: 0,
  initRotationX: 0,
  initRotationY: 0,
  initRotationZ: 0,
  initScaleX: 1,
  initScaleY: 1,
  initScaleZ: 1,
  collisionEnabled: true,
  staticEnabled: true,
  massKg: 1.0,
  gravityScale: 1.0,
  objectColor: [1.0, 1.0, 1.0, 1.0]
}

/**
 * Asset 13 with ROLE.DISCOVER defaultRole
 */
export const asset513WithDiscoverDefaultRoleSeeded: IAssetWithIds = {
  name: 'Test Asset asset513WithDiscoverDefaultRoleSeeded',
  _id: '6451da94977a0e7282ddbf32',
  role: roleStubDefaultDiscover,
  createdAt: '2023-04-19T10:00:00.000Z',
  updatedAt: '2023-04-19T11:00:00.000Z',
  assetType: ASSET_TYPE.MESH,
  description: 'A test asset for testing',
  mirrorPublicLibrary: true,
  customData: '507f191e810c19729de860ea',
  creator: '507f1f77bcf86cd799439014',
  public: true,
  thumbnail: 'test-thumbnail.jpg',
  tags: ['tag1', 'tag2'],
  tagsV2: [mockTagAMirrorPublicLibrary._id, mockTagBMirrorPublicLibrary._id],
  currentFile: 'test-file.jpg',
  initPositionX: 0,
  initPositionY: 0,
  initPositionZ: 0,
  initRotationX: 0,
  initRotationY: 0,
  initRotationZ: 0,
  initScaleX: 1,
  initScaleY: 1,
  initScaleZ: 1,
  collisionEnabled: true,
  staticEnabled: true,
  massKg: 1.0,
  gravityScale: 1.0,
  objectColor: [1.0, 1.0, 1.0, 1.0]
}

/**
 * Asset 14 with ROLE.NO_ROLE defaultRole
 */
export const asset514WithNoRoleDefaultRoleSeeded: IAssetWithIds = {
  name: 'Test Asset asset514WithNoRoleDefaultRoleSeeded',
  _id: '6451dbebb2ff97c35460196e',
  role: roleStubDefaultNoRole,
  createdAt: '2023-04-19T10:00:00.000Z',
  updatedAt: '2023-04-19T11:00:00.000Z',
  assetType: ASSET_TYPE.MESH,
  description: 'A test asset for testing',
  mirrorPublicLibrary: true,
  customData: '507f191e810c19729de860ea',
  creator: '507f1f77bcf86cd799439014',
  public: true,
  thumbnail: 'test-thumbnail.jpg',
  tags: ['tag1', 'tag2'],
  tagsV2: [mockTagAMirrorPublicLibrary._id, mockTagBMirrorPublicLibrary._id],
  currentFile: 'test-file.jpg',
  initPositionX: 0,
  initPositionY: 0,
  initPositionZ: 0,
  initRotationX: 0,
  initRotationY: 0,
  initRotationZ: 0,
  initScaleX: 1,
  initScaleY: 1,
  initScaleZ: 1,
  collisionEnabled: true,
  staticEnabled: true,
  massKg: 1.0,
  gravityScale: 1.0,
  objectColor: [1.0, 1.0, 1.0, 1.0]
}

export const asset515ToBeCreatedDefaultRoleNoRole: ICreateAssetDtoWithIds = {
  defaultRole: ROLE.NO_ROLE,
  name: 'asset515ToBeCreatedDefaultRoleNoRole',
  assetType: ASSET_TYPE.MESH,
  description: 'A test asset for E2E testing',
  mirrorPublicLibrary: false,
  public: true,
  thumbnail: 'test-thumbnail.jpg',
  tags: ['tag1', 'tag2'],
  tagsV2: [mockTagAMirrorPublicLibrary._id, mockTagBMirrorPublicLibrary._id],
  currentFile: 'test-file.jpg',
  initPositionX: 0,
  initPositionY: 0,
  initPositionZ: 0,
  initRotationX: 0,
  initRotationY: 0,
  initRotationZ: 0,
  initScaleX: 1,
  initScaleY: 1,
  initScaleZ: 1,
  collisionEnabled: true,
  staticEnabled: true,
  massKg: 1.0,
  gravityScale: 1.0,
  objectColor: [1.0, 1.0, 1.0, 1.0]
}

export const asset516ToBeCreatedDefaultRoleObserver: ICreateAssetDtoWithIds = {
  defaultRole: ROLE.OBSERVER,
  name: 'asset516ToBeCreatedDefaultRoleObserver',
  assetType: ASSET_TYPE.MESH,
  description: 'A test asset for E2E testing',
  mirrorPublicLibrary: false,
  public: true,
  thumbnail: 'test-thumbnail.jpg',
  tags: ['tag1', 'tag2'],
  tagsV2: [mockTagAMirrorPublicLibrary._id, mockTagBMirrorPublicLibrary._id],
  currentFile: 'test-file.jpg',
  initPositionX: 0,
  initPositionY: 0,
  initPositionZ: 0,
  initRotationX: 0,
  initRotationY: 0,
  initRotationZ: 0,
  initScaleX: 1,
  initScaleY: 1,
  initScaleZ: 1,
  collisionEnabled: true,
  staticEnabled: true,
  massKg: 1.0,
  gravityScale: 1.0,
  objectColor: [1.0, 1.0, 1.0, 1.0]
}

export const asset517ToBeCreatedDefaultRoleDiscover: ICreateAssetDtoWithIds = {
  defaultRole: ROLE.DISCOVER,
  name: 'asset517ToBeCreatedDefaultRoleDiscover',
  assetType: ASSET_TYPE.MESH,
  description: 'A test asset for E2E testing',
  mirrorPublicLibrary: false,
  public: true,
  thumbnail: 'test-thumbnail.jpg',
  tags: ['tag1', 'tag2'],
  tagsV2: [mockTagAMirrorPublicLibrary._id, mockTagBMirrorPublicLibrary._id],
  currentFile: 'test-file.jpg',
  initPositionX: 0,
  initPositionY: 0,
  initPositionZ: 0,
  initRotationX: 0,
  initRotationY: 0,
  initRotationZ: 0,
  initScaleX: 1,
  initScaleY: 1,
  initScaleZ: 1,
  collisionEnabled: true,
  staticEnabled: true,
  massKg: 1.0,
  gravityScale: 1.0,
  objectColor: [1.0, 1.0, 1.0, 1.0]
}

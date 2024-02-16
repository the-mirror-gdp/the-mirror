import { SpaceObject } from '../../src/space-object/space-object.schema'
import { CreateSpaceObjectDto } from './../../src/space-object/dto/create-space-object.dto'
import { asset500, asset506Seeded, materialAsset501 } from './asset.model.stub'
import { ModelStub } from './model.stub'
import {
  space10WithManagerDefaultRole,
  space14WithNoRoleDefaultRole
} from './space.model.stub'

export class SpaceObjectModelStub extends ModelStub {}

type OverrideProperties = 'creator' | 'asset' | 'customData' | 'space' | 'role'
export interface ISpaceObjectWithStringIds
  extends Omit<SpaceObject, OverrideProperties> {
  creator: string
  asset: string
  space: string
  customData?: string
  createdAt: string
  updatedAt: string
}

export const defaultCustomData0ForSpaceObjects = {
  _id: '6440b100b85e5f6cbce1aa35',
  data: {},
  createdAt: '2023-03-14T15:27:41.416Z',
  updatedAt: '2023-03-14T15:27:42.416Z'
}

/**
 * SpaceObject 1 in Private Space
 */
export const creatorUserAId = '6440afbed504b85dd92ab968'
export const customData500Id = '6440b0010e534d9569ababe4' // I'm running out of naming schemes, so starting custom data at 5xx

export const spaceObject1InPrivateSpace: ISpaceObjectWithStringIds = {
  _id: '6440c22a23036d24c076b634',
  space: space14WithNoRoleDefaultRole._id,
  name: 'A Newly-Created Space Object Instance',
  description: 'A test space object',
  creator: '6440b93350092cbd2282e236',
  asset: asset500._id,
  customData: defaultCustomData0ForSpaceObjects._id,
  isGroup: false,
  parentId: null,
  locked: false,
  position: [0.0, 0.0, 0.0],
  rotation: [0.0, 0.0, 0.0],
  scale: [1.0, 1.0, 1.0],
  offset: [0.0, 0.0, 0.0],
  collisionEnabled: true,
  shapeType: 'Auto',
  bodyType: 'Static',
  staticEnabled: true,
  massKg: 1,
  gravityScale: 1,
  materialAssetId: materialAsset501._id,
  objectColor: [1.0, 1.0, 1.0, 1.0],
  objectTexture: '',
  objectTextureSize: 1.0,
  objectTextureOffset: [1.0, 1.0, 1.0],
  objectTextureRepeat: false,
  objectTextureSizeV2: [1.0, 1.0, 1.0],
  objectTextureTriplanar: false,
  audioAutoPlay: true,
  audioLoop: true,
  audioIsSpatial: true,
  audioPitch: 100.0,
  audioBaseVolume: 100.0,
  audioSpatialMaxVolume: 150.0,
  audioSpatialRange: 0.0,
  scriptEvents: [],
  extraNodes: [],
  createdAt: '2023-04-19T10:00:00.000Z',
  updatedAt: '2023-04-19T11:00:00.000Z'
}

/**
 * SpaceObject 2 in Public Manager Space (space.role.defaultRole = ROLE.MANAGER)
 */
export const creatorUserBId = '6440afd8a37c2b471ee07dd1'
export const customData501Id = '6440aff3e6126317c7a1f4bb' // I'm running out of naming schemes, so starting custom data at 5xx

export const spaceObject2InPublicManagerSpace: ISpaceObjectWithStringIds = {
  _id: '6440c22fa4a0592944440df6',
  space: space10WithManagerDefaultRole._id,
  name: 'A Newly-Created Space Object Instance',
  description: 'A test space object',
  creator: '6440b9390f688604f3c81609',
  asset: asset500._id,
  customData: defaultCustomData0ForSpaceObjects._id,
  isGroup: false,
  parentId: null,
  locked: false,
  position: [0.0, 0.0, 0.0],
  rotation: [0.0, 0.0, 0.0],
  scale: [1.0, 1.0, 1.0],
  offset: [0.0, 0.0, 0.0],
  collisionEnabled: true,
  shapeType: 'Auto',
  bodyType: 'Static',
  staticEnabled: true,
  massKg: 1,
  gravityScale: 1,
  materialAssetId: materialAsset501._id,
  objectColor: [1.0, 1.0, 1.0, 1.0],
  objectTexture: '',
  objectTextureSize: 1.0,
  objectTextureOffset: [1.0, 1.0, 1.0],
  objectTextureRepeat: false,
  objectTextureSizeV2: [1.0, 1.0, 1.0],
  objectTextureTriplanar: false,
  audioAutoPlay: true,
  audioLoop: true,
  audioIsSpatial: true,
  audioPitch: 100.0,
  audioBaseVolume: 100.0,
  audioSpatialMaxVolume: 150.0,
  audioSpatialRange: 0.0,
  scriptEvents: [],
  extraNodes: [],
  createdAt: '2023-04-19T10:00:00.000Z',
  updatedAt: '2023-04-19T11:00:00.000Z'
}

/**
 * SpaceObject 3 in Private Space to be created
 */

export const spaceObject3ToBeCreatedInPrivateSpace: CreateSpaceObjectDto = {
  spaceId: space14WithNoRoleDefaultRole._id,
  name: 'A Newly-Created Space Object Instance spaceObject3InPrivateSpace',
  description: 'A test space object',
  asset: asset500._id,
  locked: false,
  position: [0.0, 0.0, 0.0],
  rotation: [0.0, 0.0, 0.0],
  scale: [1.0, 1.0, 1.0],
  offset: [0.0, 0.0, 0.0],
  collisionEnabled: true,
  shapeType: 'Auto',
  bodyType: 'Static',
  staticEnabled: true,
  massKg: 1,
  gravityScale: 1,
  materialAssetId: materialAsset501._id,
  objectColor: [1.0, 1.0, 1.0, 1.0],
  objectTexture: '',
  objectTextureSize: 1.0,
  objectTextureTriplanar: false,
  audioAutoPlay: true,
  audioLoop: true,
  audioIsSpatial: true,
  audioPitch: 100.0,
  audioBaseVolume: 100.0,
  audioSpatialMaxVolume: 150.0,
  audioSpatialRange: 0.0,
  scriptEvents: [],
  extraNodes: []
}

/**
 * SpaceObject 4 in Manager Space to be created
 */

export const spaceObject4ToBeCreatedInManagerSpace: CreateSpaceObjectDto = {
  spaceId: space10WithManagerDefaultRole._id,
  name: 'A Newly-Created Space Object Instance spaceObject4ToBeCreatedInManagerSpace',
  description: 'A test space object',
  asset: asset500._id,
  locked: false,
  position: [0.0, 0.0, 0.0],
  rotation: [0.0, 0.0, 0.0],
  scale: [1.0, 1.0, 1.0],
  offset: [0.0, 0.0, 0.0],
  collisionEnabled: true,
  shapeType: 'Auto',
  bodyType: 'Static',
  staticEnabled: true,
  massKg: 1,
  gravityScale: 1,
  materialAssetId: materialAsset501._id,
  objectColor: [1.0, 1.0, 1.0, 1.0],
  objectTexture: '',
  objectTextureSize: 1.0,
  objectTextureTriplanar: false,
  audioAutoPlay: true,
  audioLoop: true,
  audioIsSpatial: true,
  audioPitch: 100.0,
  audioBaseVolume: 100.0,
  audioSpatialMaxVolume: 150.0,
  audioSpatialRange: 0.0,
  scriptEvents: [],
  extraNodes: []
}

/**
 * SpaceObject 5 to be created with specified Asset 502
 */

export const spaceObject5ToBeCreatedWithSpecifiedAssetNeedsAssetId: Partial<CreateSpaceObjectDto> =
  {
    spaceId: space10WithManagerDefaultRole._id,
    name: 'A Newly-Created Space Object Instance spaceObject5ToBeCreatedWithSpecifiedAssetNeedsAssetId',
    description:
      'A test space object spaceObject5ToBeCreatedWithSpecifiedAssetNeedsAssetId',
    locked: false,
    position: [0.0, 0.0, 0.0],
    rotation: [0.0, 0.0, 0.0],
    scale: [1.0, 1.0, 1.0],
    offset: [0.0, 0.0, 0.0],
    collisionEnabled: true,
    shapeType: 'Auto',
    bodyType: 'Static',
    staticEnabled: true,
    massKg: 1,
    gravityScale: 1,
    materialAssetId: materialAsset501._id,
    objectColor: [1.0, 1.0, 1.0, 1.0],
    objectTexture: '',
    objectTextureSize: 1.0,
    objectTextureTriplanar: false,
    audioAutoPlay: true,
    audioLoop: true,
    audioIsSpatial: true,
    audioPitch: 100.0,
    audioBaseVolume: 100.0,
    audioSpatialMaxVolume: 150.0,
    audioSpatialRange: 0.0,
    scriptEvents: [],
    extraNodes: []
  }

/**
 * SpaceObject 6 to be created with specified Asset 503
 */

export const spaceObject6ToBeCreatedWithSpecifiedAssetNeedsAssetId: Partial<CreateSpaceObjectDto> =
  {
    spaceId: space10WithManagerDefaultRole._id,
    name: 'Name: A Newly-Created Space Object Instance spaceObject6ToBeCreatedWithSpecifiedAssetNeedsAssetId',
    description:
      'Desc: A test space object spaceObject6ToBeCreatedWithSpecifiedAssetNeedsAssetId',
    locked: false,
    position: [0.0, 0.0, 0.0],
    rotation: [0.0, 0.0, 0.0],
    scale: [1.0, 1.0, 1.0],
    offset: [0.0, 0.0, 0.0],
    collisionEnabled: true,
    shapeType: 'Auto',
    bodyType: 'Static',
    staticEnabled: true,
    massKg: 1,
    gravityScale: 1,
    materialAssetId: materialAsset501._id,
    objectColor: [1.0, 1.0, 1.0, 1.0],
    objectTexture: '',
    objectTextureSize: 1.0,
    objectTextureTriplanar: false,
    audioAutoPlay: true,
    audioLoop: true,
    audioIsSpatial: true,
    audioPitch: 100.0,
    audioBaseVolume: 100.0,
    audioSpatialMaxVolume: 150.0,
    audioSpatialRange: 0.0,
    scriptEvents: [],
    extraNodes: []
  }

export const spaceObject7ForSeededAsset506: ISpaceObjectWithStringIds = {
  _id: '6450181a8f00d6ad3b0169ca',
  space: space10WithManagerDefaultRole._id,
  name: 'A Newly-Created Space Object Instance for an Asset. spaceObject7ForSeededAsset506',
  description: 'A test space object. spaceObject7ForSeededAsset506',
  creator: '6440b9390f688604f3c81609',
  asset: asset506Seeded._id,
  customData: defaultCustomData0ForSpaceObjects._id,
  isGroup: false,
  parentId: null,
  locked: false,
  position: [0.0, 0.0, 0.0],
  rotation: [0.0, 0.0, 0.0],
  scale: [1.0, 1.0, 1.0],
  offset: [0.0, 0.0, 0.0],
  collisionEnabled: true,
  shapeType: 'Auto',
  bodyType: 'Static',
  staticEnabled: true,
  massKg: 1,
  gravityScale: 1,
  materialAssetId: materialAsset501._id,
  objectColor: [1.0, 1.0, 1.0, 1.0],
  objectTexture: '',
  objectTextureSize: 1.0,
  objectTextureOffset: [1.0, 1.0, 1.0],
  objectTextureRepeat: false,
  objectTextureSizeV2: [1.0, 1.0, 1.0],
  objectTextureTriplanar: false,
  audioAutoPlay: true,
  audioLoop: true,
  audioIsSpatial: true,
  audioPitch: 100.0,
  audioBaseVolume: 100.0,
  audioSpatialMaxVolume: 150.0,
  audioSpatialRange: 0.0,
  scriptEvents: [],
  extraNodes: [],
  createdAt: '2023-04-19T10:00:00.000Z',
  updatedAt: '2023-04-19T11:00:00.000Z'
}

export const spaceObject7ForParentSpaceObjectInManagerSpace: ISpaceObjectWithStringIds =
  {
    _id: '64a3870bdab2d6ab82462b7d',
    space: space10WithManagerDefaultRole._id,
    name: 'spaceObject7ForParentSpaceObjectInManagerSpace',
    description: 'desc:spaceObject7ForParentSpaceObjectInManagerSpace',
    creator: '6440b9390f688604f3c81609',
    asset: asset500._id,
    customData: defaultCustomData0ForSpaceObjects._id,
    isGroup: false,
    parentId: null,
    locked: false,
    position: [0.0, 0.0, 0.0],
    rotation: [0.0, 0.0, 0.0],
    scale: [1.0, 1.0, 1.0],
    offset: [0.0, 0.0, 0.0],
    collisionEnabled: true,
    shapeType: 'Auto',
    bodyType: 'Static',
    staticEnabled: true,
    massKg: 1,
    gravityScale: 1,
    materialAssetId: materialAsset501._id,
    objectColor: [1.0, 1.0, 1.0, 1.0],
    objectTexture: '',
    objectTextureSize: 1.0,
    objectTextureOffset: [1.0, 1.0, 1.0],
    objectTextureRepeat: false,
    objectTextureSizeV2: [1.0, 1.0, 1.0],
    objectTextureTriplanar: false,
    audioAutoPlay: true,
    audioLoop: true,
    audioIsSpatial: true,
    audioPitch: 100.0,
    audioBaseVolume: 100.0,
    audioSpatialMaxVolume: 150.0,
    audioSpatialRange: 0.0,
    scriptEvents: [],
    extraNodes: [],
    createdAt: '2023-04-19T10:00:00.000Z',
    updatedAt: '2023-04-19T11:00:00.000Z'
  }

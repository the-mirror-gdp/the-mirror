import { ObjectId } from 'mongodb'
import { CreateZoneDto } from '../../src/zone/dto/create-zone.dto'
import { CONTAINER_STATE } from '../../src/zone/space-manager-external.service'
import {
  Zone,
  zoneIsInBadStateCheck,
  ZONE_MODE
} from '../../src/zone/zone.schema'
import { ModelStub } from './model.stub'
import {
  space17ForZoneToBeCreated,
  space18SeededForSeededZone,
  space19ForZoneToBeCreatedWithSpaceVersion
} from './space.model.stub'
import { spaceVersion1 } from './spaceVersion.model.stub'
import { mockUser0, mockUser1OwnerOfZone } from './user.model.stub'

export class ZoneModelStub extends ModelStub {}

type OverrideProperties =
  | 'creator'
  | 'customData'
  | 'owner'
  | 'space'
  | 'spaceVersion'
  | 'usersPresent'
export interface IZoneWithObjectIds extends Omit<Zone, OverrideProperties> {
  _id?: ObjectId
  customData?: ObjectId
  space: ObjectId
  spaceVersion: ObjectId
  owner: ObjectId
  usersPresent: ObjectId[]
  createdAt: string
  updatedAt: string
}

/**
 * Zone 1: To be created
 */
export const zone1ToBeCreated: CreateZoneDto = {
  zoneMode: ZONE_MODE.PLAY,
  space: space17ForZoneToBeCreated._id,
  name: 'zone1ToBeCreated',
  description: 'desc: zone1ToBeCreated',
  spaceVersion: spaceVersion1._id,
  url: 'http://24.239.31.126:8000/api/spaces/3bce2bc0-0c9f-11ee-a381-0242ac1c0105',
  uuid: '3bce2bc0-0c9f-11ee-a381-0242ac1c0105',
  ipAddress: 'Mock Address',
  port: 8080,
  state: CONTAINER_STATE.READY,
  gdServerVersion: '5.1.0'
}

/**
 * Zone 2: To be created many
 */
export const zone2ToBeCreatedMany: CreateZoneDto = {
  zoneMode: ZONE_MODE.PLAY,
  space: space17ForZoneToBeCreated._id,
  name: 'zone2ToBeCreatedMany',
  description: 'desc: zone2ToBeCreatedMany',
  spaceVersion: spaceVersion1._id,
  url: 'http://24.239.31.126:8000/api/spaces/759c008a-0c9e-11ee-a381-0242ac1c0105',
  uuid: '759c008a-0c9e-11ee-a381-0242ac1c0105',
  ipAddress: 'Mock Address',
  port: 8080,
  state: CONTAINER_STATE.READY,
  gdServerVersion: '5.1.0'
}

/**
 * Zone 3: To be created with nonexistent spaceId
 */
export const zone3NonexistentSpaceId: CreateZoneDto = {
  zoneMode: ZONE_MODE.PLAY,
  space: '64502db5dfcc52730e402d73',
  name: 'zone3NonexistentSpaceId',
  description: 'desc: zone3NonexistentSpaceId',
  spaceVersion: spaceVersion1._id,
  url: 'http://24.239.31.126:8000/api/spaces/4d6a0bc0-0c9e-11ee-a381-0242ac1c0105',
  uuid: '4d6a0bc0-0c9e-11ee-a381-0242ac1c0105',
  ipAddress: 'Mock Address',
  port: 8080,
  state: CONTAINER_STATE.READY,
  gdServerVersion: '5.1.0'
}

/**
 * Zone 4: usersPresent Seeded
 */
export const zone4UsersPresentSeeded: IZoneWithObjectIds = {
  _id: new ObjectId('645035db6336eaad9aef48b0'),
  name: 'Mock Zone zone4UsersPresentSeeded',
  owner: new ObjectId(mockUser1OwnerOfZone._id),
  zoneMode: ZONE_MODE.BUILD,
  space: new ObjectId(space18SeededForSeededZone._id),
  description: 'Mock Zone Description zone4UsersPresentSeeded',
  url: 'http://24.239.31.126:8000/api/spaces/c0548a42-c8bb-11ed-98b3-0242ac1c0105',
  uuid: 'd0548a42-c8bb-11ed-98b3-0242ac1c0105',
  ipAddress: 'Mock Address',
  port: 8080,
  state: CONTAINER_STATE.READY,
  spaceVersion: new ObjectId('648e5819184dd04be1e54be7'),
  gdServerVersion: '5.1.0',
  usersPresent: [
    new ObjectId(mockUser0._id),
    new ObjectId(mockUser1OwnerOfZone._id)
  ],
  createdAt: '2023-04-19T00:00:00.000Z',
  updatedAt: '2023-04-19T00:00:00.000Z',
  containerLastRefreshed: new Date(),
  isInBadState: zoneIsInBadStateCheck
}

/**
 * Zone 5: To be created with spaceVersionId
 */
export const zone5ToBeCreatedPlayWithSpaceVersion: CreateZoneDto = {
  zoneMode: ZONE_MODE.PLAY,
  space: space19ForZoneToBeCreatedWithSpaceVersion._id,
  spaceVersion: spaceVersion1._id,
  name: 'zone5ToBeCreatedPlay',
  description: 'desc: zone5ToBeCreatedPlay',
  url: 'http://24.239.31.126:8000/api/spaces/407bbdc8-0c9e-11ee-a381-0242ac1c0105',
  uuid: '407bbdc8-0c9e-11ee-a381-0242ac1c0105',
  ipAddress: 'Mock Address',
  port: 8080,
  state: CONTAINER_STATE.READY,
  gdServerVersion: '5.1.0'
}

import { ObjectId } from 'mongodb'
import { Asset } from '../../src/asset/asset.schema'
import { ASSET_TYPE } from '../../src/option-sets/asset-type'
import { ROLE } from '../../src/roles/models/role.enum'
import { Role, userIsOwnerCheck } from '../../src/roles/models/role.schema'
import { ModelStub } from './model.stub'
import mongoose from 'mongoose'

export class RoleModelStub extends ModelStub {}

type OverrideProperties = 'createdAt' | 'updatedAt'
export interface IRoleWithStringIds extends Omit<Role, OverrideProperties> {
  createdAt: string
  updatedAt: string
}

export const roleStubDefaultOwner: IRoleWithStringIds = {
  _id: '647ebea0d9d277a5057a28d2',
  defaultRole: ROLE.OWNER,
  users: new Map([
    ['60f9d45b1234567890123457', ROLE.OWNER],
    ['60f9d45b1234567890123458', ROLE.MANAGER],
    ['60f9d45b1234567890123459', ROLE.OBSERVER]
  ]),
  userGroups: new Map([
    ['60f9d45b1234567890123460', ROLE.OWNER],
    ['60f9d45b1234567890123461', ROLE.MANAGER],
    ['6440b522f311d2e78ce4898b', ROLE.OBSERVER]
  ]),
  creator: new mongoose.Types.ObjectId('60f9d45b1234567890123457'),
  createdAt: '2023-03-14T15:27:41.416Z',
  updatedAt: '2023-03-14T15:27:42.416Z',
  userIsOwner: userIsOwnerCheck
}

export const roleStubDefaultManager: IRoleWithStringIds = {
  _id: '60f9d45b1234567890123456',
  defaultRole: ROLE.MANAGER,
  users: new Map([
    ['60f9d45b1234567890123457', ROLE.OWNER],
    ['60f9d45b1234567890123458', ROLE.MANAGER],
    ['60f9d45b1234567890123459', ROLE.OBSERVER]
  ]),
  userGroups: new Map([
    ['60f9d45b1234567890123460', ROLE.OWNER],
    ['60f9d45b1234567890123461', ROLE.MANAGER],
    ['6440b522f311d2e78ce4898b', ROLE.OBSERVER]
  ]),
  creator: new mongoose.Types.ObjectId('60f9d45b1234567890123457'),
  createdAt: '2023-03-14T15:27:41.416Z',
  updatedAt: '2023-03-14T15:27:42.416Z',
  userIsOwner: userIsOwnerCheck
}

export const roleStubDefaultContributor: IRoleWithStringIds = {
  _id: '6440b60c1b4b6792b18a548b',
  defaultRole: ROLE.CONTRIBUTOR,
  users: new Map([
    ['60f9d45b1234567890123457', ROLE.OWNER],
    ['60f9d45b1234567890123458', ROLE.MANAGER],
    ['60f9d45b1234567890123459', ROLE.OBSERVER]
  ]),
  userGroups: new Map([
    ['60f9d45b1234567890123460', ROLE.OWNER],
    ['60f9d45b1234567890123461', ROLE.MANAGER],
    ['6440b522f311d2e78ce4898b', ROLE.OBSERVER]
  ]),
  creator: new mongoose.Types.ObjectId('60f9d45b1234567890123457'),
  createdAt: '2023-03-14T15:27:41.416Z',
  updatedAt: '2023-03-14T15:27:42.416Z',
  userIsOwner: userIsOwnerCheck
}

export const roleStubDefaultObserver: IRoleWithStringIds = {
  _id: '6440b619ceb481f8c98ab24b',
  defaultRole: ROLE.OBSERVER,
  users: new Map([
    ['60f9d45b1234567890123457', ROLE.OWNER],
    ['60f9d45b1234567890123458', ROLE.MANAGER],
    ['60f9d45b1234567890123459', ROLE.OBSERVER]
  ]),
  userGroups: new Map([
    ['60f9d45b1234567890123460', ROLE.OWNER],
    ['60f9d45b1234567890123461', ROLE.MANAGER],
    ['6440b522f311d2e78ce4898b', ROLE.OBSERVER]
  ]),
  creator: new mongoose.Types.ObjectId('60f9d45b1234567890123457'),
  createdAt: '2023-03-14T15:27:41.416Z',
  updatedAt: '2023-03-14T15:27:42.416Z',
  userIsOwner: userIsOwnerCheck
}

export const roleStubDefaultDiscover: IRoleWithStringIds = {
  _id: '6440b638e2ca0fe112b565ca',
  defaultRole: ROLE.DISCOVER,
  users: new Map([
    ['60f9d45b1234567890123457', ROLE.OWNER],
    ['60f9d45b1234567890123458', ROLE.MANAGER],
    ['60f9d45b1234567890123459', ROLE.OBSERVER]
  ]),
  userGroups: new Map([
    ['60f9d45b1234567890123460', ROLE.OWNER],
    ['60f9d45b1234567890123461', ROLE.MANAGER],
    ['6440b522f311d2e78ce4898b', ROLE.OBSERVER]
  ]),
  creator: new mongoose.Types.ObjectId('60f9d45b1234567890123457'),
  createdAt: '2023-03-14T15:27:41.416Z',
  updatedAt: '2023-03-14T15:27:42.416Z',
  userIsOwner: userIsOwnerCheck
}

export const roleStubDefaultNoRole: IRoleWithStringIds = {
  _id: '6440b6452cb424016829e93b',
  defaultRole: ROLE.NO_ROLE,
  users: new Map([['60f9d45b1234567890123457', ROLE.OWNER]]),
  userGroups: new Map([
    ['6440d906d58d61781c37ea90', ROLE.OWNER],
    ['60f9d45b1234567890123461', ROLE.MANAGER],
    ['6440b522f311d2e78ce4898b', ROLE.OBSERVER]
  ]),
  creator: new mongoose.Types.ObjectId('60f9d45b1234567890123457'),
  createdAt: '2023-03-14T15:27:41.416Z',
  updatedAt: '2023-03-14T15:27:42.416Z',
  userIsOwner: userIsOwnerCheck
}

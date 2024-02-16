import mongoose, { Document } from 'mongoose'
import { UserGroup } from '../user-groups/user-group.schema'
import { User } from '../user/user.schema'
import { ROLE } from './models/role.enum'
import { Role } from './models/role.schema'

export interface IRoleConsumer {
  // Entity CRUD
  /**
   * START Section: Create
   */
  /**
   * @description This is optional in case a service has discriminators/classes for a schema and needs to have separate create methods
   * @date 2023-04-01 00:46
   */
  createOneWithRolesCheck?(userId: string, dto: any): Promise<Partial<Document>>
  /**
   * @description This is where the business logic resides for what role level constitutes "create" access
   */
  canCreateWithRolesCheck(
    userId: string,
    data?: any // optional for create, but could be info like the spaceId for a spaceObject, where the user would need permissions to create a SpaceObject in a certain Space
  ): Promise<boolean> | boolean
  /**
   * END Section: Create
   */

  /**
   * START Section: Read
   */
  findOneWithRolesCheck(
    userId: string,
    entityId: string
  ): Promise<Partial<Document>>
  /**
   * @description This is where the business logic resides for what role level constitutes "read" access
   */
  canFindWithRolesCheck(
    userId: string,
    entityWithPopulatedProperties: any
  ): Promise<boolean> | boolean
  /**
   * END Section: Read
   */

  /**
   * START Section: Update
   */
  updateOneWithRolesCheck(
    userId: string,
    entityId: string,
    dto: any
  ): Promise<Partial<Document>>
  canUpdateWithRolesCheck(
    userId: string,
    entityWithPopulatedProperties: any
  ): Promise<boolean> | boolean
  /**
   * END Section: Update
   */

  /**
   * START Section: Delete
   */
  removeOneWithRolesCheck(userId: string, entityId: string): Promise<Document>
  canRemoveWithRolesCheck(
    userId: string,
    entityWithPopulatedProperties: any
  ): Promise<boolean> | boolean
  /**
   * END Section: Delete
   */

  /**
   * START Section: Owner permissions for role modification
   */
  setUserRoleForOneWithOwnerCheck(
    requestingUserId: string,
    targetUserId: string,
    spaceId: string,
    role: ROLE
  )
  removeUserRoleForOneWithOwnerCheck(
    requestingUserId: string,
    targetUserId: string,
    spaceId: string
  )

  // TODO: add when groups are implemented
  // setUserGroupRoleForOne(
  //   requestingUserId: string,
  //   userGroupId: string,
  //   spaceId: string,
  //   role: ROLE
  // )
  // removeUserGroupRoleForOne(
  //   requestingUserId: string,
  //   userGroupId,
  //   spaceId: string
  // )
  /**
   * END Section: Owner permissions for role modification
   */

  // wip: define for roles here
  // allowListProperties: Map<ROLE, string[]>
}

/**
 * @description Loose interface for a DB schema. This enforces a Role document to be present on the schema.
 */
export interface ISchemaWithRole {
  role: Role
}

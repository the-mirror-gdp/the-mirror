import {
  BadRequestException,
  Injectable,
  InternalServerErrorException,
  Logger
} from '@nestjs/common'
import { InjectModel } from '@nestjs/mongoose'
import { validateOrReject } from 'class-validator'
import { isNil, max, min } from 'lodash'
import { Model, PipelineStage } from 'mongoose'
import { aggregationMatchId, UserId } from '../util/mongo-object-id-helpers'
import { CreateRoleDto } from './dto/create-role.dto'
import { ROLE } from './models/role.enum'
import { Role, RoleDocument } from './models/role.schema'

@Injectable()
export class RoleService {
  constructor(
    private readonly logger: Logger,
    @InjectModel(Role.name)
    private roleModel: Model<RoleDocument>
  ) {}

  /**
   * @description Helper for aggregation pipelines to keep this DRY. This populates role and checks if the user has greater than or equal to the role level. This is the newer method to use instead of getMaxRoleForUserForEntity()
   * @date 2023-05-03 04:22
   */
  public getRoleCheckAggregationPipeline(userId: UserId, gteRoleLevel) {
    const userChecks = userId
      ? [
          {
            $or: [
              { [`role.users.${userId}`]: { $gte: gteRoleLevel } },
              { 'role.defaultRole': { $gte: gteRoleLevel } }
            ]
          },
          //ensure that the user is not banned
          {
            $or: [
              { [`role.users.${userId}`]: { $exists: false } },
              { [`role.users.${userId}`]: { $gte: 0 } } //negative numbers indicate banned
            ]
          }
        ]
      : [{ 'role.defaultRole': { $gte: gteRoleLevel } }]

    const pipeline: PipelineStage[] = [
      {
        $match: {
          $and:
            userId === undefined
              ? [{ 'role.defaultRole': { $eq: gteRoleLevel } }]
              : userChecks
        }
      }
    ]

    return pipeline
  }

  /**
   * @description Helper for aggregation pipelines to keep this DRY
   * includeRoleLookup should be set to false if `role` is already looked up/populated on the entity
   * @date 2023-05-03 05:50:41
   */
  public userIsOwnerAggregationPipeline(userId: UserId) {
    const pipeline: PipelineStage[] = [
      {
        $match: {
          $or: [
            {
              [`role.users.${userId}`]: { $gte: ROLE.OWNER }
            }
          ]
        }
      }
    ]

    return pipeline
  }

  /**
   * @description This is the newest method that should be used to check a user's role for an entity
   * It's more optimized since it uses an aggregation pipeline.
   * @date 2023-05-04 03:08
   */
  public async checkUserRoleForEntity(
    userId: UserId,
    idToCheck: string,
    gteRole: ROLE,
    model
  ) {
    const pipeline = [
      aggregationMatchId(idToCheck),
      ...this.getRoleCheckAggregationPipeline(userId, gteRole)
    ]
    const data = await model.aggregate(pipeline).exec()

    if (data && data[0]) {
      return true
    } else {
      return false
    }
  }

  /**
   * @deprecated use getRoleCheckAggregationPipeline() instead. This is synchronous and it should instead be done in an aggregation pipeline.
   * @description This is the primary helper function of the RoleService.
   * These properties MUST be populated on the entity:
   * 'role' (Role)
   * @returns the highest ROLE (number) the user has for the entity
   * @date 2023-03-29 23:26
   */
  public getMaxRoleForUserForEntity(
    userId: string,
    entityWithPopulatedProperties: any
  ): ROLE {
    // shortening for readability. I put the long param name to make it clear what's being passed in and lessen human errors
    // check that the required properties exist
    this._checkForRequiredPopulatedProperties(entityWithPopulatedProperties)
    // first, check if user is an owner
    if (entityWithPopulatedProperties.role.userIsOwner(userId) === true) {
      return ROLE.OWNER
    }

    const roleNumbers = []
    // add the default role
    if (entityWithPopulatedProperties.role?.defaultRole !== undefined) {
      roleNumbers.push(entityWithPopulatedProperties.role.defaultRole)
    }

    // check if userId is on Role document for having a ROLE
    if (
      entityWithPopulatedProperties.role.users &&
      entityWithPopulatedProperties.role.users.has(userId)
    ) {
      roleNumbers.push(entityWithPopulatedProperties.role.users.get(userId))
    }

    // check the access level
    return this._getAccessLevelFromRoles(roleNumbers)
  }

  /**
   * @deprecated this inserts the role doc, which we aren't doing anymore
   * @date 2023-07-20 17:07
   */
  async create(dto: CreateRoleDto) {
    // we need to manually call validateOrReject since we're not using a controller
    try {
      await validateOrReject(dto)
    } catch (errors) {
      throw new BadRequestException(
        'Caught promise rejection for Role creation (validation failed). Errors: ',
        errors
      )
    }
    const createdRole = new this.roleModel(dto)
    // set the creator as an owner
    createdRole.users.set(dto.creator, ROLE.OWNER)
    const doc = await createdRole.save()
    return doc
  }

  /**
   * @description Checks multiple levels of cascading permissions for whether the user has exact access to the entity
   * TODO also create and input Role[] for a UserGroup in the same format. That way, we can check UserGroup permissions.
   * @date 2023-03-16 15:53
   */
  private _getAccessLevelFromRoles(roleNumbers: ROLE[]): ROLE {
    // NOTE: these are ROLEs, which is an enum of number values, NOT the Role (class) nor RoleDocument

    // find the lowest role. If below 0, return that
    const lowestNegativeRole: ROLE | undefined = min(roleNumbers)
    if (lowestNegativeRole !== undefined && lowestNegativeRole < ROLE.NO_ROLE) {
      return lowestNegativeRole
    }

    // find the highest role
    const highestRole: ROLE | undefined = max(roleNumbers)
    // if undefined still, return no role
    if (highestRole === undefined) {
      return ROLE.NO_ROLE
    }

    return highestRole
  }

  /**
   * @description Ensures that these are true, or else throws an error:
   * all: role, role.defaultRole
   */
  private _checkForRequiredPopulatedProperties(entity: any & { role: Role }) {
    // ensure the populated properties are passed in; otherwise, throw an error
    let check = true
    if (isNil(!entity.role) || isNil(!entity?.role?.defaultRole)) {
      check = false
    }

    if (!check) {
      // TODO: add these to filtered logging
      console.error(
        `_checkForRequiredPopulatedProperties: role was not populated. Entity: ${JSON.stringify(
          entity,
          null,
          2
        )}`,
        `${RoleService.name}._checkForRequiredPopulatedProperties`
      )
      throw new InternalServerErrorException()
    }
  }
}

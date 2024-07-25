import {
  MessageBody,
  SubscribeMessage,
  WebSocketGateway
} from '@nestjs/websockets'
import { SpaceObjectService } from './space-object.service'
import { Logger, UseFilters, UseGuards, UseInterceptors } from '@nestjs/common'
import { CreateSpaceObjectDto } from './dto/create-space-object.dto'
import { UpdateSpaceObjectDto } from './dto/update-space-object.dto'
import { UpdateBatchSpaceObjectDto } from './dto/update-batch-space-object.dto'
import { GodotSocketInterceptor } from '../godot-server/godot-socket.interceptor'
import { GodotSocketExceptionFilter } from '../godot-server/godot-socket-exception.filter'
import { SpaceObjectId, UserId } from '../util/mongo-object-id-helpers'
import {
  AdminTokenWS,
  UserTokenWS
} from '../godot-server/get-user-ws.decorator'
import { da } from 'date-fns/locale'
import { WsAuthGuard } from '../godot-server/ws-auth.guard'

enum ZoneSpaceObjectWsMessage {
  GET = 'zone_get_space_object',
  CREATE = 'zone_create_space_object',
  UPDATE = 'zone_update_space_object',
  REMOVE = 'zone_delete_space_object',
  GET_PAGE = 'zone_get_space_objects_page',
  GET_BATCH = 'zone_get_batch_space_objects',
  GET_PRELOAD_SPACE_OBJECTS = 'zone_get_preload_space_objects',
  UPDATE_BATCH = 'zone_update_batch_space_objects',
  REMOVE_BATCH = 'zone_delete_batch_space_objects'
}

@WebSocketGateway()
@UseGuards(WsAuthGuard)
@UseInterceptors(GodotSocketInterceptor)
@UseFilters(GodotSocketExceptionFilter)
export class SpaceObjectGateway {
  constructor(
    private readonly spaceObjectService: SpaceObjectService,
    private readonly logger: Logger
  ) {}

  @SubscribeMessage(ZoneSpaceObjectWsMessage.CREATE)
  public create(
    @AdminTokenWS() isAdmin: boolean,
    @UserTokenWS('user_id') userId: UserId,
    @MessageBody('dto')
    createSpaceObjectDto: CreateSpaceObjectDto & { creatorUserId?: UserId }
  ) {
    this.logger.log(
      `${JSON.stringify(
        {
          ZoneSpaceObjectWsMessage: ZoneSpaceObjectWsMessage.CREATE,
          createSpaceObjectDto: createSpaceObjectDto
          // TODO: this needs to be updated to include the creator's user ID! 2023-04-21 01:01:06. Do not merge until the Godot server adds that in.
        },
        null,
        2
      )}`,
      SpaceObjectGateway.name
    )

    if (userId) {
      return this.spaceObjectService.createOneWithRolesCheck(
        userId,
        createSpaceObjectDto
      )
    }

    if (isAdmin) {
      return this.spaceObjectService.createOneAdmin(createSpaceObjectDto)
    }
    return
  }

  @SubscribeMessage(ZoneSpaceObjectWsMessage.GET_PAGE)
  public getAllBySpaceIdPaginated(
    @AdminTokenWS() isAdmin: boolean,
    @UserTokenWS('user_id') userId: UserId,
    @MessageBody('id') spaceId: string,
    @MessageBody('page') page: number,
    @MessageBody('perPage') perPage: number
  ) {
    this.logger.log(
      `${JSON.stringify(
        {
          ZoneSpaceObjectWsMessage: ZoneSpaceObjectWsMessage.GET_PAGE,
          spaceId,
          page,
          perPage
        },
        null,
        2
      )}`,
      SpaceObjectGateway.name
    )

    if (isAdmin) {
      return this.spaceObjectService.getAllBySpaceIdPaginatedAdmin(spaceId, {
        page,
        perPage
      })
    }

    if (userId) {
      return this.spaceObjectService.getAllBySpaceIdPaginatedWithRolesCheck(
        userId,
        spaceId,
        {
          page,
          perPage
        }
      )
    }
    return
  }

  @SubscribeMessage(ZoneSpaceObjectWsMessage.GET_BATCH)
  public findMany(
    @AdminTokenWS() isAdmin: boolean,
    @UserTokenWS('user_id') userId: UserId,
    @MessageBody('batch') ids: string[],
    @MessageBody('page') page: number,
    @MessageBody('perPage') perPage: number
  ) {
    this.logger.log(
      `${JSON.stringify(
        {
          ZoneSpaceObjectWsMessage: ZoneSpaceObjectWsMessage.GET_BATCH,
          'batch (ids)': ids,
          page,
          perPage
        },
        null,
        2
      )}`,
      SpaceObjectGateway.name
    )
    if (isAdmin) {
      return this.spaceObjectService.findManyAdmin(ids, { page, perPage })
    }

    if (userId) {
      return this.spaceObjectService.findManyWithRolesCheck(userId, ids, {
        page,
        perPage
      })
    }
    return
  }

  @SubscribeMessage(ZoneSpaceObjectWsMessage.GET_PRELOAD_SPACE_OBJECTS)
  public getAllPreloadSpaceObjectsBySpaceIdPaginated(
    @AdminTokenWS() isAdmin: boolean,
    @UserTokenWS('user_id') userId: UserId,
    @MessageBody('id') spaceId: string,
    @MessageBody('page') page: number,
    @MessageBody('perPage') perPage: number
  ) {
    const options = { space: spaceId, preloadBeforeSpaceStarts: true }
    this.logger.log(
      `${JSON.stringify(
        {
          ZoneSpaceObjectWsMessage:
            ZoneSpaceObjectWsMessage.GET_PRELOAD_SPACE_OBJECTS,
          spaceId,
          page,
          perPage,
          options
        },
        null,
        2
      )}`,
      SpaceObjectGateway.name
    )

    if (isAdmin) {
      return this.spaceObjectService.getAllBySpaceIdPaginatedAdmin(
        spaceId,
        {
          page,
          perPage
        },
        options
      )
    }

    if (userId) {
      return this.spaceObjectService.getAllBySpaceIdPaginatedWithRolesCheck(
        userId,
        spaceId,
        {
          page,
          perPage
        },
        options
      )
    }
    return
  }

  /**
   * @description Returns the spaceObject with optional populated properties
   * populateParent: true: populates the single parentSpaceObject property to be the object
   * recursiveParentLookup: true: will recursively populate the parentSpaceObject property AND the parentSpaceObject (so populateParent is disregarded)
   * recursiveChildrenPopulate: true: will recursively populate childSpaceObjects
   *
   * Walkthrough: https://www.loom.com/share/a4e5e27f27b849fabdb1806235c7e48b
   * @date 2023-07-04 17:43
   */
  @SubscribeMessage(ZoneSpaceObjectWsMessage.GET)
  public async findOneWithSingleParentSpaceObject(
    @AdminTokenWS() isAdmin: boolean,
    @UserTokenWS('user_id') userId: UserId,
    @MessageBody('id') spaceObjectId: SpaceObjectId,
    @MessageBody('populateParent') populateParent = false, // if true, decently fast, 1 lookup
    @MessageBody('recursiveParentPopulate') recursiveParentPopulate = false, // if true, slower with $graphLookup
    @MessageBody('recursiveChildrenPopulate') recursiveChildrenPopulate = false // if true, slowest because 2 $graphLookups
  ) {
    if (!isAdmin && !userId) {
      return
    }
    this.logger.log(
      `${JSON.stringify(
        {
          ZoneSpaceObjectWsMessage: ZoneSpaceObjectWsMessage.GET,
          id: spaceObjectId,
          populateParent,
          recursiveParentPopulate,
          recursiveChildrenPopulate
        },
        null,
        2
      )}`,
      SpaceObjectGateway.name
    )
    let returnData: any
    // first check the parent populates, prioritizing recursiveParentPopulate
    if (recursiveParentPopulate) {
      returnData =
        await this.spaceObjectService.findOneAdminWithPopulatedParentSpaceObjectRecursiveLookup(
          spaceObjectId
        )
    } else if (populateParent) {
      returnData =
        await this.spaceObjectService.findOneAdminWithPopulatedParentSpaceObject(
          spaceObjectId
        )
    } else {
      // no recursive parent lookup nor parent lookup, so just find the spaceObject by itself
      let data

      if (userId) {
        data = await this.spaceObjectService.findOneWithRolesCheck(
          userId,
          spaceObjectId
        )
      }

      if (isAdmin) {
        data = await this.spaceObjectService.findOneAdmin(spaceObjectId)
      }

      returnData = data.toJSON() // needs to be converted to JSON so it can be modified below
    }

    // check children populates
    if (recursiveChildrenPopulate) {
      const childLookup =
        await this.spaceObjectService.findOneAdminWithPopulatedChildSpaceObjectsRecursiveLookup(
          spaceObjectId
        )
      // if it worked, merge the data

      if (childLookup) {
        returnData['childSpaceObjects'] = childLookup.childSpaceObjects
      } else {
        returnData['childSpaceObjects'] = []
      }
    }

    return returnData
  }

  @SubscribeMessage(ZoneSpaceObjectWsMessage.UPDATE_BATCH)
  public async updateMany(
    @UserTokenWS('user_id') userId: UserId,
    @AdminTokenWS() isAdmin: boolean,
    @MessageBody() batchDto: UpdateBatchSpaceObjectDto
  ) {
    this.logger.log(
      `${JSON.stringify(
        {
          ZoneSpaceObjectWsMessage: ZoneSpaceObjectWsMessage.UPDATE_BATCH,
          batchDto
        },
        null,
        2
      )}`,
      SpaceObjectGateway.name
    )

    if (isAdmin) {
      return await this.spaceObjectService.updateManyAdmin(batchDto)
    }

    if (userId) {
      return await this.spaceObjectService.updateManyWithRolesCheck(
        userId,
        batchDto
      )
    }
    return
  }

  @SubscribeMessage(ZoneSpaceObjectWsMessage.UPDATE)
  public updateOne(
    @AdminTokenWS() isAdmin: boolean,
    @UserTokenWS('user_id') userId: UserId,
    @MessageBody('id') id: string,
    @MessageBody('dto') updateSpaceObjectDto: UpdateSpaceObjectDto
  ) {
    this.logger.log(
      `${JSON.stringify(
        {
          ZoneSpaceObjectWsMessage: ZoneSpaceObjectWsMessage.UPDATE,
          id,
          updateSpaceObjectDto
        },
        null,
        2
      )}`,
      SpaceObjectGateway.name
    )

    if (userId) {
      return this.spaceObjectService.updateOneWithRolesCheck(
        userId,
        id,
        updateSpaceObjectDto
      )
    }

    if (isAdmin) {
      return this.spaceObjectService.updateOneAdmin(id, updateSpaceObjectDto)
    }
    return
  }

  @SubscribeMessage(ZoneSpaceObjectWsMessage.REMOVE_BATCH)
  public removeMany(
    @UserTokenWS('user_id') userId: UserId,
    @AdminTokenWS() isAdmin: boolean,
    @MessageBody('batch') ids: string[]
  ) {
    this.logger.log(
      `${JSON.stringify(
        {
          ZoneSpaceObjectWsMessage: ZoneSpaceObjectWsMessage.REMOVE_BATCH,
          'batch (ids)': ids
        },
        null,
        2
      )}`,
      SpaceObjectGateway.name
    )

    if (isAdmin) {
      return this.spaceObjectService.removeManyAdmin(ids)
    }

    if (userId) {
      return this.spaceObjectService.removeManyWithRolesCheck(userId, ids)
    }
    return
  }

  @SubscribeMessage(ZoneSpaceObjectWsMessage.REMOVE)
  public removeOne(
    @AdminTokenWS() isAdmin: boolean,
    @UserTokenWS('user_id') userId: UserId,
    @MessageBody('id') id: string
  ) {
    this.logger.log(
      `${JSON.stringify(
        {
          ZoneSpaceObjectWsMessage: ZoneSpaceObjectWsMessage.REMOVE,
          id: id
        },
        null,
        2
      )}`,
      SpaceObjectGateway.name
    )

    if (userId) {
      return this.spaceObjectService.removeOneWithRolesCheck(userId, id)
    }

    if (isAdmin) {
      return this.spaceObjectService.removeOneAdmin(id)
    }
    return
  }
}

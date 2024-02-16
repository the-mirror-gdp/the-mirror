import {
  MessageBody,
  SubscribeMessage,
  WebSocketGateway
} from '@nestjs/websockets'
import { SpaceObjectService } from './space-object.service'
import { Logger, UseFilters, UseInterceptors } from '@nestjs/common'
import { CreateSpaceObjectDto } from './dto/create-space-object.dto'
import { UpdateSpaceObjectDto } from './dto/update-space-object.dto'
import { UpdateBatchSpaceObjectDto } from './dto/update-batch-space-object.dto'
import { GodotSocketInterceptor } from '../godot-server/godot-socket.interceptor'
import { GodotSocketExceptionFilter } from '../godot-server/godot-socket-exception.filter'
import { SpaceObjectId, UserId } from '../util/mongo-object-id-helpers'

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
@UseInterceptors(GodotSocketInterceptor)
@UseFilters(GodotSocketExceptionFilter)
export class SpaceObjectGateway {
  constructor(
    private readonly spaceObjectService: SpaceObjectService,
    private readonly logger: Logger
  ) {}

  @SubscribeMessage(ZoneSpaceObjectWsMessage.CREATE)
  public create(
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
    // TODO: this needs to be updated to include the creator's user ID! 2023-04-21 01:01:06. Do not merge until the Godot server adds that in.
    return this.spaceObjectService.createOneAdmin(createSpaceObjectDto)
  }

  @SubscribeMessage(ZoneSpaceObjectWsMessage.GET_PAGE)
  public getAllBySpaceIdPaginated(
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
    return this.spaceObjectService.getAllBySpaceIdPaginatedAdmin(spaceId, {
      page,
      perPage
    })
  }

  @SubscribeMessage(ZoneSpaceObjectWsMessage.GET_BATCH)
  public findMany(
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
    return this.spaceObjectService.findManyAdmin(ids, { page, perPage })
  }

  @SubscribeMessage(ZoneSpaceObjectWsMessage.GET_PRELOAD_SPACE_OBJECTS)
  public getAllPreloadSpaceObjectsBySpaceIdPaginated(
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
    return this.spaceObjectService.getAllBySpaceIdPaginatedAdmin(
      spaceId,
      {
        page,
        perPage
      },
      options
    )
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
    @MessageBody('id') spaceObjectId: SpaceObjectId,
    @MessageBody('populateParent') populateParent = false, // if true, decently fast, 1 lookup
    @MessageBody('recursiveParentPopulate') recursiveParentPopulate = false, // if true, slower with $graphLookup
    @MessageBody('recursiveChildrenPopulate') recursiveChildrenPopulate = false // if true, slowest because 2 $graphLookups
  ) {
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
      returnData = (
        await this.spaceObjectService.findOneAdmin(spaceObjectId)
      ).toJSON() // needs to be converted to JSON so it can be modified below
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
  public async updateMany(@MessageBody() batchDto: UpdateBatchSpaceObjectDto) {
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
    return await this.spaceObjectService.updateManyAdmin(batchDto)
  }

  @SubscribeMessage(ZoneSpaceObjectWsMessage.UPDATE)
  public updateOne(
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
    return this.spaceObjectService.updateOneAdmin(id, updateSpaceObjectDto)
  }

  @SubscribeMessage(ZoneSpaceObjectWsMessage.REMOVE_BATCH)
  public removeMany(@MessageBody('batch') ids: string[]) {
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
    return this.spaceObjectService.removeManyAdmin(ids)
  }

  @SubscribeMessage(ZoneSpaceObjectWsMessage.REMOVE)
  public removeOne(@MessageBody('id') id: string) {
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
    return this.spaceObjectService.removeOneAdmin(id)
  }
}

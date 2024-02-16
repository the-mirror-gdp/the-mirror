import { Injectable, Logger } from '@nestjs/common'
import { FilterQuery, Model, PipelineStage } from 'mongoose'
import {
  ISort,
  IPaginatedResponse,
  PaginationInterface,
  SORT_DIRECTION,
  NewPaginationInterface,
  IPaginationPipeline
} from './pagination.interface'
import { PaginationData, PaginationDataByStartItem } from './pagination-data'
import { UserId } from '../mongo-object-id-helpers'
import { ROLE } from '../../roles/models/role.enum'
import { flatten, gte } from 'lodash'
import { RoleService } from '../../roles/role.service'
import { PAGINATION_STRATEGY } from './pagination-strategy.enum'

export interface PopulateField {
  localField: string
  from: string
  unwind: boolean
  project?: object
}
@Injectable()
export class PaginationService {
  constructor(
    private readonly logger: Logger,
    private roleService: RoleService
  ) {}

  /**
   * @deprecated
   */
  public async getPaginatedQueryResponse<T>(
    model: Model<T>,
    options: FilterQuery<any>,
    pagination: PaginationInterface,
    sort: ISort = { updatedAt: SORT_DIRECTION.DESC } // default: sort by updatedAt descending
  ): Promise<IPaginatedResponse<T>> {
    const paginationData = new PaginationData({ ...pagination })
    const query = model.find(options, {}, { sort })

    try {
      paginationData.total = await model.count(options).exec()
      const data = await query
        .skip((paginationData.page - 1) * paginationData.perPage)
        .limit(paginationData.perPage)
        .exec()

      paginationData.totalPage = Math.ceil(
        paginationData.total / paginationData.perPage
      )

      return { data, ...paginationData }
    } catch (error: any) {
      throw error
    }
  }

  public async getPaginationPipelineByPageWithRolesCheck<T>(
    userId: UserId,
    model: Model<T>,
    matchFilter: object,
    gteRoleLevel: ROLE,
    pagination: PaginationInterface,
    populate: PopulateField[] = [],
    sort: ISort = { updatedAt: SORT_DIRECTION.DESC }
  ): Promise<IPaginationPipeline<PaginationData>> {
    const paginationData = new PaginationData({ ...pagination })

    const populateStages = flatten(
      populate.map((data) => {
        const innerPipeline: any[] = [
          {
            $match: {
              $expr: {
                $eq: ['$_id', '$$localField']
              }
            }
          }
        ]
        // optionally project, if present
        data.project &&
          innerPipeline.push({
            $project: {
              ...data.project
            }
          })
        const returnData: any[] = [
          {
            $lookup: {
              from: data.from,
              let: { localField: `$${data.localField}` },
              pipeline: innerPipeline,
              as: data.localField
            }
          }
        ]
        if (data.unwind) {
          returnData.push({
            $unwind: {
              path: `$${data.localField}`,
              preserveNullAndEmptyArrays: true // mongodb aggregation won't output the document if the field is empty and this is false
            }
          })
        }
        return returnData
      })
    )
    const mainPipeline = [
      { $match: matchFilter },
      ...this.roleService.getRoleCheckAggregationPipeline(userId, gteRoleLevel),
      ...populateStages
    ]

    const countResult = await model.aggregate([
      ...mainPipeline,
      {
        $count: 'count'
      }
    ])

    paginationData.total = countResult.length > 0 ? countResult[0].count : 0
    paginationData.totalPage = Math.ceil(
      paginationData.total / paginationData.perPage
    )

    //Pipeline for case insensitive sorting

    const sortPipeLine: PipelineStage[] = [
      {
        $addFields: {
          dataToSort: {
            $trim: { input: { $toLower: `$${Object.keys(sort)[0]}` } }
          }
        }
      },
      {
        $sort: {
          dataToSort: sort[`${Object.keys(sort)[0]}`]
        }
      },
      {
        $project: {
          dataToSort: 0
        }
      }
    ]

    const paginationPipeline: PipelineStage[] = [
      ...mainPipeline,
      ...sortPipeLine,
      { $skip: (paginationData.page - 1) * paginationData.perPage },
      { $limit: paginationData.perPage }
    ]

    return { paginationPipeline, paginationData }
  }

  /**
   * @description This runs the Roles check query server-side rather than client-side. This is a much better implementation than client-side role checks and should be used in the future.
   * @date 2023-04-24 19:42
   */
  public async getPaginatedQueryResponseWithRolesCheck<T>(
    userId: UserId,
    model: Model<T>,
    matchFilter: object,
    gteRoleLevel: ROLE,
    pagination: PaginationInterface,
    populate: PopulateField[] = [],
    sort: ISort = { updatedAt: SORT_DIRECTION.DESC } // default: sort by updatedAt descending
  ): Promise<IPaginatedResponse<T>> {
    const { paginationPipeline, paginationData } =
      await this.getPaginationPipelineByPageWithRolesCheck(
        userId,
        model,
        matchFilter,
        gteRoleLevel,
        pagination,
        populate,
        sort
      )

    const data = await model.aggregate(paginationPipeline)

    return { data, ...paginationData }
  }

  /**
   * @description Admin version of getPaginatedQueryResponseWithRolesCheck. The shared functionality should be ...shared at some point to stay DRY.
   * @date 2023-04-24 19:42
   */
  public async getPaginatedQueryResponseAdmin<T>(
    model: Model<T>,
    matchFilter: object,
    pagination: PaginationInterface,
    populate: PopulateField[] = [],
    sort: ISort = { updatedAt: SORT_DIRECTION.DESC } // default: sort by updatedAt descending
  ): Promise<IPaginatedResponse<T>> {
    const paginationData = new PaginationData({ ...pagination })

    const populateStages = flatten(
      populate.map((data) => {
        return [
          {
            $lookup: {
              from: data.from,
              localField: data.localField,
              foreignField: '_id',
              as: data.localField
            }
          },
          {
            $unwind: {
              path: `$${data.localField}`,
              preserveNullAndEmptyArrays: true // mongodb aggregation won't output the document if the field is empty and this is false
            }
          }
        ]
      })
    )
    const mainPipeline = [{ $match: matchFilter }, ...populateStages]

    const countResult = await model.aggregate([
      ...mainPipeline,
      {
        $count: 'count'
      }
    ])

    paginationData.total = countResult.length > 0 ? countResult[0].count : 0
    paginationData.totalPage = Math.ceil(
      paginationData.total / paginationData.perPage
    )

    const queryPipeline: PipelineStage[] = [
      ...mainPipeline,
      { $sort: sort },
      { $skip: (paginationData.page - 1) * paginationData.perPage },
      { $limit: paginationData.perPage }
    ]

    const data = await model.aggregate(queryPipeline)

    return { data, ...paginationData }
  }

  public async getPaginationPipelineByStartItemWithRolesCheck<T>(
    userId: UserId,
    model: Model<T>,
    matchFilter: object,
    gteRoleLevel: ROLE,
    pagination: NewPaginationInterface,
    populate: PopulateField[] = [],
    sort: ISort = { updatedAt: SORT_DIRECTION.DESC } // default: sort by updatedAt descending
  ): Promise<IPaginationPipeline<PaginationDataByStartItem>> {
    const paginationData = new PaginationDataByStartItem({ ...pagination })

    const populateStages = flatten(
      populate.map((data) => {
        const innerPipeline: any[] = [
          {
            $match: {
              $expr: {
                $eq: ['$_id', '$$localField']
              }
            }
          }
        ]
        // optionally project, if present
        data.project &&
          innerPipeline.push({
            $project: {
              ...data.project
            }
          })
        const returnData: any[] = [
          {
            $lookup: {
              from: data.from,
              let: { localField: `$${data.localField}` },
              pipeline: innerPipeline,
              as: data.localField
            }
          }
        ]
        if (data.unwind) {
          returnData.push({
            $unwind: {
              path: `$${data.localField}`,
              preserveNullAndEmptyArrays: true // mongodb aggregation won't output the document if the field is empty and this is false
            }
          })
        }
        return returnData
      })
    )
    const mainPipeline = [
      { $match: matchFilter },
      ...this.roleService.getRoleCheckAggregationPipeline(userId, gteRoleLevel),
      ...populateStages
    ]

    const countResult = await model.aggregate([
      ...mainPipeline,
      {
        $count: 'count'
      }
    ])

    paginationData.total = countResult.length > 0 ? countResult[0].count : 0
    paginationData.totalPage = Math.ceil(
      paginationData.total / paginationData.numberOfItems
    )

    //Pipeline for case insensitive sorting

    const sortPipeLine: PipelineStage[] = [
      {
        $addFields: {
          dataToSort: {
            $trim: { input: { $toLower: `$${Object.keys(sort)[0]}` } }
          }
        }
      },
      {
        $sort: {
          dataToSort: sort[`${Object.keys(sort)[0]}`]
        }
      },
      {
        $project: {
          dataToSort: 0
        }
      }
    ]

    const paginationPipeline: PipelineStage[] = [
      ...mainPipeline,
      ...sortPipeLine,
      { $skip: paginationData.startItem },
      { $limit: paginationData.numberOfItems }
    ]

    return { paginationPipeline, paginationData }
  }

  public async getPaginatedQueryResponseByStartItemWithRolesCheck<T>(
    userId: UserId,
    model: Model<T>,
    matchFilter: object,
    gteRoleLevel: ROLE,
    pagination: NewPaginationInterface,
    populate: PopulateField[] = [],
    sort: ISort = { updatedAt: SORT_DIRECTION.DESC } // default: sort by updatedAt descending
  ): Promise<IPaginatedResponse<T>> {
    const { paginationPipeline, paginationData } =
      await this.getPaginationPipelineByStartItemWithRolesCheck(
        userId,
        model,
        matchFilter,
        gteRoleLevel,
        pagination,
        populate,
        sort
      )

    const data = await model.aggregate(paginationPipeline)

    return { data, ...paginationData }
  }

  public async getPaginationPipelineWithRolesCheck<T>(
    userId: UserId,
    model: Model<T>,
    matchFilter: object,
    gteRoleLevel: ROLE,
    pagination: PaginationInterface | NewPaginationInterface,
    populate: PopulateField[] = [],
    sort: ISort = { updatedAt: SORT_DIRECTION.DESC },
    paginationStrategy: PAGINATION_STRATEGY
  ) {
    if (paginationStrategy === PAGINATION_STRATEGY.START_ITEM) {
      return await this.getPaginationPipelineByStartItemWithRolesCheck(
        userId,
        model,
        matchFilter,
        gteRoleLevel,
        pagination,
        populate,
        sort
      )
    } else {
      return await this.getPaginationPipelineByPageWithRolesCheck(
        userId,
        model,
        matchFilter,
        gteRoleLevel,
        pagination,
        populate,
        sort
      )
    }
  }

  public getPaginationStrategy(
    startItem: number,
    numberOfItems: number
  ): PAGINATION_STRATEGY {
    return startItem !== null &&
      startItem !== undefined &&
      numberOfItems !== null &&
      numberOfItems !== undefined
      ? PAGINATION_STRATEGY.START_ITEM
      : PAGINATION_STRATEGY.PAGE
  }
}

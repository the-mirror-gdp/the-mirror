import { FilterQuery, Model, PipelineStage } from 'mongoose'
import { getLowQualitySpacesFilterAggregationPipeline } from './get-low-quality-spaces-filter.pipeline'
import { PopulateField } from '../../util/pagination/pagination.service'
import {
  IPaginationPipeline,
  NewPaginationInterface,
  PaginationInterface,
  SORT_DIRECTION
} from '../../util/pagination/pagination.interface'
import { SpaceDocument } from '../space.schema'
import { PAGINATION_STRATEGY } from '../../util/pagination/pagination-strategy.enum'
import {
  PaginationData,
  PaginationDataByStartItem
} from '../../util/pagination/pagination-data'
import { getSpaceObjectCountAggregationPipeline } from './get-space-object-count.pipeline'

const mostActiveSpacesPipeline: PipelineStage[] = [
  { $match: { usersCount: { $gt: 0 } } },
  { $sort: { usersCount: -1, name: -1 } },
  {
    $group: {
      _id: null,
      data: {
        $push: '$$ROOT'
      }
    }
  },
  {
    $unwind: {
      path: '$data',
      includeArrayIndex: 'popularSpaceIndex'
    }
  },
  {
    $replaceRoot: {
      newRoot: {
        $mergeObjects: [
          '$data',
          {
            popularSpaceIndex: {
              $multiply: ['$popularSpaceIndex', 2]
            }
          }
        ]
      }
    }
  }
]

const highestRatedSpacesPipeline: PipelineStage[] = [
  {
    $sort: {
      AVG_RATING: -1,
      name: -1
    }
  },
  {
    $group: {
      _id: null,
      data: {
        $push: '$$ROOT'
      }
    }
  },
  {
    $unwind: {
      path: '$data',
      includeArrayIndex: 'popularSpaceIndex'
    }
  },
  {
    $replaceRoot: {
      newRoot: {
        $mergeObjects: [
          '$data',
          {
            popularSpaceIndex: {
              $add: [1, { $multiply: [2, '$popularSpaceIndex'] }]
            }
          }
        ]
      }
    }
  }
]

const getPopularSpacesWithLowQualitySpacesFilterAggregationPipeline = (
  matchFilter: FilterQuery<SpaceDocument>,
  roleChecksPipeline: PipelineStage[],
  sortDirection: SORT_DIRECTION = SORT_DIRECTION.ASC
): PipelineStage[] => [
  { $match: matchFilter },
  ...roleChecksPipeline,
  ...getLowQualitySpacesFilterAggregationPipeline(),
  {
    $facet: {
      mostActive:
        mostActiveSpacesPipeline as PipelineStage.FacetPipelineStage[],
      highestRated:
        highestRatedSpacesPipeline as PipelineStage.FacetPipelineStage[]
    }
  },
  {
    $project: {
      combinedSpaces: { $concatArrays: ['$mostActive', '$highestRated'] }
    }
  },
  { $unwind: { path: '$combinedSpaces' } },
  //Make sure the spaces are unique
  {
    $group: {
      _id: '$combinedSpaces._id',
      space: { $first: '$combinedSpaces' }
    }
  },
  {
    $replaceRoot: { newRoot: '$space' }
  },
  {
    $sort: { popularSpaceIndex: sortDirection }
  },
  {
    $project: {
      popularSpaceIndex: 0
    }
  }
]

const getPopularSpacesWithoutFilterAggregationPipeline = (
  matchFilter: FilterQuery<SpaceDocument>,
  roleChecksPipeline: PipelineStage[],
  sortDirection: SORT_DIRECTION = SORT_DIRECTION.ASC
): PipelineStage[] => [
  { $match: matchFilter },
  ...roleChecksPipeline,
  ...getSpaceObjectCountAggregationPipeline(),
  {
    $facet: {
      mostActive: [
        { $match: { spaceObjectCount: { $gt: 5 } } },
        ...mostActiveSpacesPipeline
      ] as PipelineStage.FacetPipelineStage[],
      highestRated: [
        { $match: { spaceObjectCount: { $gt: 5 } } },
        ...highestRatedSpacesPipeline
      ] as PipelineStage.FacetPipelineStage[],
      lowQuality: [
        {
          $match: { spaceObjectCount: { $lte: 5 } }
        },
        { $sort: { usersCount: -1, AVG_RATING: -1, name: -1 } },
        { $addFields: { isLowQuality: true } }
      ] as PipelineStage.FacetPipelineStage[]
    }
  },
  {
    $project: {
      combinedSpaces: {
        $concatArrays: ['$mostActive', '$highestRated', '$lowQuality']
      }
    }
  },
  { $unwind: { path: '$combinedSpaces' } },
  //Make sure the spaces are unique
  {
    $group: {
      _id: '$combinedSpaces._id',
      space: { $first: '$combinedSpaces' }
    }
  },
  {
    $replaceRoot: { newRoot: '$space' }
  },
  {
    $sort: { isLowQuality: sortDirection, popularSpaceIndex: sortDirection }
  },
  {
    $project: {
      popularSpaceIndex: 0,
      isLowQuality: 0,
      spaceObjectCount: 0
    }
  }
]

export const getPopularSpacesAggregationPipeline = async (
  spaceModel: Model<SpaceDocument>,
  roleChecksPipeline: PipelineStage[],
  pagination: PaginationInterface | NewPaginationInterface,
  paginationStrategy: PAGINATION_STRATEGY,
  filterLowQualitySpaces = false,
  sortDirection: SORT_DIRECTION = SORT_DIRECTION.ASC,
  populateFields: PopulateField[] = [],
  matchFilter: FilterQuery<SpaceDocument> = {}
): Promise<{
  paginatedResult: SpaceDocument[]
  paginationData: PaginationData | PaginationDataByStartItem
}> => {
  //We process each of pipelines separately and add popularSpaceIndex to each space.
  //For mostActiveSpacesPipeline index will have the form 2k and for highestRatedSpacesPipeline it will be 2k+1.
  //This way we can achieve M H M H ... pattern
  //Then we combine the results and sort by popularSpaceIndex.

  const pipeline: PipelineStage[] = filterLowQualitySpaces
    ? getPopularSpacesWithLowQualitySpacesFilterAggregationPipeline(
        matchFilter,
        roleChecksPipeline,
        sortDirection
      )
    : getPopularSpacesWithoutFilterAggregationPipeline(
        matchFilter,
        roleChecksPipeline,
        sortDirection
      )

  if (populateFields && populateFields.length > 0) {
    populateFields.forEach((field) => {
      const populateStage: PipelineStage = {
        $lookup: {
          from: field.from,
          localField: field.localField,
          foreignField: '_id',
          as: field.localField
        }
      }

      pipeline.push(populateStage)

      if (field.unwind) {
        const unwindStage: PipelineStage = {
          $unwind: {
            path: `$${field.localField}`,
            preserveNullAndEmptyArrays: true
          }
        }
        pipeline.push(unwindStage)
      }

      if (field.project) {
        const projectStage: PipelineStage = {
          $project: field.project
        }
        pipeline.push(projectStage)
      }
    })
  }

  //We cant use existing pagination methods because we need to save the order of popular spaces
  //and perform all $match stages before pagination

  const paginationData =
    paginationStrategy === PAGINATION_STRATEGY.START_ITEM
      ? new PaginationDataByStartItem({ ...pagination })
      : new PaginationData({ ...pagination })

  const filteredData = await spaceModel.aggregate([...pipeline])

  paginationData.total = filteredData.length

  const totalPage =
    paginationStrategy === PAGINATION_STRATEGY.START_ITEM
      ? paginationData.total /
        (paginationData as PaginationDataByStartItem).numberOfItems
      : paginationData.total / (paginationData as PaginationData).perPage

  paginationData.totalPage = Math.ceil(totalPage)

  const firstElement =
    paginationStrategy === PAGINATION_STRATEGY.START_ITEM
      ? (paginationData as PaginationDataByStartItem).startItem
      : ((paginationData as PaginationData).page - 1) *
        (paginationData as PaginationData).perPage

  const lastElement =
    firstElement +
    ((paginationData as PaginationData).perPage
      ? (paginationData as PaginationData).perPage
      : (paginationData as PaginationDataByStartItem).numberOfItems)

  const paginatedResult = filteredData.slice(firstElement, lastElement)

  return { paginatedResult, paginationData }
}

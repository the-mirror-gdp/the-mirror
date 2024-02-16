import { PipelineStage } from 'mongoose'
import { PopulateField } from '../../util/pagination/pagination.service'

export const getPopulateUserEntityActionsStatsAggregationPipeline = (
  matchCondtion?: PipelineStage.Match,
  populateFields?: PopulateField[]
) => {
  const pipeline: PipelineStage[] = [
    {
      $lookup: {
        from: 'userentityactions',
        localField: '_id',
        foreignField: 'forEntity',
        as: 'entityActions'
      }
    },
    {
      $unwind: {
        path: '$entityActions',
        preserveNullAndEmptyArrays: true
      }
    },
    {
      $group: {
        _id: '$_id',
        entityDetails: { $first: '$$ROOT' },
        AVG_RATING: { $avg: '$entityActions.rating' },
        COUNT_LIKE: {
          $sum: {
            $cond: [{ $eq: ['$entityActions.actionType', 'LIKE'] }, 1, 0]
          }
        },
        COUNT_FOLLOW: {
          $sum: {
            $cond: [{ $eq: ['$entityActions.actionType', 'FOLLOW'] }, 1, 0]
          }
        },
        COUNT_SAVES: {
          $sum: {
            $cond: [{ $eq: ['$entityActions.actionType', 'SAVE'] }, 1, 0]
          }
        },
        COUNT_RATING: {
          $sum: {
            $cond: [{ $eq: ['$entityActions.actionType', 'RATING'] }, 1, 0]
          }
        }
      }
    },
    {
      $project: {
        'entityDetails.entityActions': 0
      }
    },
    {
      $replaceRoot: {
        newRoot: {
          $mergeObjects: [
            '$entityDetails',
            {
              AVG_RATING: '$AVG_RATING',
              COUNT_LIKE: '$COUNT_LIKE',
              COUNT_FOLLOW: '$COUNT_FOLLOW',
              COUNT_SAVES: '$COUNT_SAVES',
              COUNT_RATING: '$COUNT_RATING'
            }
          ]
        }
      }
    }
  ]

  if (matchCondtion) {
    pipeline.unshift(matchCondtion)
  }

  if (populateFields && populateFields.length > 0) {
    populateFields.forEach((populate) => {
      pipeline.splice(1, 0, {
        $lookup: {
          from: populate.from,
          localField: populate.localField,
          foreignField: '_id',
          as: populate.localField
        }
      })
    })
  }

  return pipeline
}

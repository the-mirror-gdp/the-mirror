import { PipelineStage } from 'mongoose'
import { PopulateField } from '../../util/pagination/pagination.service'

export const getUserStatsAndUsersPresentAggregationPipeline = (
  matchCondition?: PipelineStage.Match,
  populateFields?: PopulateField[],
  includeUserStats = false,
  includeUsersPresent = false
) => {
  const pipeline: PipelineStage[] = []

  if (matchCondition) {
    pipeline.push(matchCondition)
  }

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
            path: '$' + field.localField,
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

  if (includeUserStats) {
    pipeline.push(
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
      },
      {
        $project: { entityActions: 0 }
      }
    )
  }

  if (includeUsersPresent) {
    pipeline.push(
      {
        $lookup: {
          from: 'zones',
          localField: '_id',
          foreignField: 'space',
          as: 'zones'
        }
      },
      {
        $addFields: {
          usersCount: {
            $sum: {
              $map: {
                input: '$zones',
                as: 'zone',
                in: { $size: '$$zone.usersPresent' }
              }
            }
          },
          servers: {
            $arrayToObject: {
              $map: {
                input: '$zones',
                as: 'zone',
                in: {
                  k: { $toString: '$$zone._id' },
                  v: {
                    usersCount: { $size: '$$zone.usersPresent' },
                    usersPresent: '$$zone.usersPresent'
                  }
                }
              }
            }
          },
          usersPresent: {
            $reduce: {
              input: '$zones',
              initialValue: [],
              in: { $concatArrays: ['$$value', '$$this.usersPresent'] }
            }
          }
        }
      },
      {
        $project: { zones: 0 }
      }
    )
  }

  return pipeline
}

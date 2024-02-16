import { PipelineStage } from 'mongoose'

export const getPopulateUsersInZoneBySpaceIdAggregationPipeline = (
  matchCondition?: PipelineStage.Match
) => {
  const pipeline: PipelineStage[] = [
    {
      $lookup: {
        from: 'users',
        localField: 'usersPresent',
        foreignField: '_id',
        as: 'usersPresent'
      }
    },
    {
      $project: {
        _id: 1,
        usersCount: { $size: '$usersPresent' },
        usersPresent: 1
      }
    },
    {
      $group: {
        _id: null,
        serverData: {
          $push: {
            k: { $toString: '$_id' },
            v: {
              usersCount: '$usersCount',
              usersPresent: '$usersPresent'
            }
          }
        },
        usersCount: { $sum: '$usersCount' },
        allUsersPresent: { $push: '$usersPresent' }
      }
    },
    {
      $project: {
        _id: 0,
        servers: { $arrayToObject: '$serverData' },
        usersCount: 1,
        usersPresent: {
          $reduce: {
            input: '$allUsersPresent',
            initialValue: [],
            in: { $concatArrays: ['$$value', '$$this'] }
          }
        }
      }
    }
  ]

  if (matchCondition) {
    pipeline.unshift(matchCondition)
  }

  return pipeline
}

export const getPopulateUsersInZoneBySpaceIdNoUsersPresentPopulateAggregationPipeline =
  (matchCondition?: PipelineStage.Match) => {
    const pipeline: PipelineStage[] = [
      {
        $lookup: {
          from: 'users',
          localField: 'usersPresent',
          foreignField: '_id',
          as: 'usersPresent'
        }
      },
      {
        $project: {
          _id: 1,
          usersCount: { $size: '$usersPresent' }
        }
      },
      {
        $group: {
          _id: null,
          serverData: {
            $push: {
              k: { $toString: '$_id' },
              v: {
                usersCount: '$usersCount'
              }
            }
          },
          usersCount: { $sum: '$usersCount' }
        }
      },
      {
        $project: {
          _id: 0,
          servers: { $arrayToObject: '$serverData' },
          usersCount: 1
        }
      }
    ]

    if (matchCondition) {
      pipeline.unshift(matchCondition)
    }

    return pipeline
  }

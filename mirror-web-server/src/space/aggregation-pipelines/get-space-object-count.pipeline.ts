import { PipelineStage } from 'mongoose'

export const getSpaceObjectCountAggregationPipeline = (): PipelineStage[] => [
  {
    $lookup: {
      from: 'spaceobjects',
      localField: '_id',
      foreignField: 'space',
      as: 'spaceObjects'
    }
  },
  {
    $addFields: {
      spaceObjectCount: { $size: '$spaceObjects' }
    }
  },
  {
    $project: {
      spaceObjects: 0
    }
  }
]

import { PipelineStage } from 'mongoose'

export const getLowQualitySpacesFilterAggregationPipeline =
  (): PipelineStage[] => [
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
      $match: {
        spaceObjectCount: { $gte: 5 }
      }
    },
    {
      $project: {
        spaceObjects: 0,
        spaceObjectCount: 0
      }
    }
  ]

import { PipelineStage } from 'mongoose'
import { PopulateField } from '../pagination/pagination.service'

export class AggregationPipelines {
  public static getPipelineForGetByIdOrdered(
    idsArray: string[],
    populateFields: PopulateField[] = []
  ): PipelineStage[] {
    const pipeline: PipelineStage[] = [
      { $match: { _id: { $in: idsArray } } },
      { $addFields: { __order: { $indexOfArray: [idsArray, '$_id'] } } },
      { $sort: { __order: 1 } }
    ]

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
            $unwind: '$' + field.localField
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

    return pipeline
  }
}

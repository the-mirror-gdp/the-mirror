import { BadRequestException, Injectable } from '@nestjs/common'
import { InjectModel } from '@nestjs/mongoose'
import { keyBy } from 'lodash'
import { Model } from 'mongoose'
import { SpaceVariablesDataId } from '../util/mongo-object-id-helpers'
import { CreateSpaceVariablesDataDocumentDto } from './dto/space-variables-data.dto'
import {
  SpaceVariablesData,
  SpaceVariablesDataDocument
} from './models/space-variables-data.schema'
import flat from 'flat'
import { ObjectId } from 'mongodb'

@Injectable()
export class SpaceVariablesDataService {
  constructor(
    @InjectModel(SpaceVariablesData.name)
    private spaceVariablesDataModel: Model<SpaceVariablesDataDocument>
  ) {}

  async createSpaceVariablesDataDocument(
    spaceVariablesDataDto: CreateSpaceVariablesDataDocumentDto
  ): Promise<SpaceVariablesDataDocument> {
    const spaceVariablesDataDocument = new this.spaceVariablesDataModel({
      ...spaceVariablesDataDto
    })

    return await spaceVariablesDataDocument.save()
  }

  /**
   * @description If spaceVariablesDataDocumentId is empty, then it will create a new document
   * @date 2023-06-05 18:34
   */
  async updateSpaceVariablesDataAdmin(
    spaceVariablesDataDocumentId: SpaceVariablesDataId,
    patchSpaceVariablesData?: object,
    removeSpaceVariablesDataKeys?: string[]
  ): Promise<SpaceVariablesDataDocument> {
    const updateData: any = {}
    if (patchSpaceVariablesData) {
      updateData.$set = flat(
        {
          data: {
            ...patchSpaceVariablesData
          }
        },
        { safe: true }
      )
    }
    if (removeSpaceVariablesDataKeys) {
      updateData.$unset = updateData.$unset = flat(
        {
          data: {
            ...keyBy(removeSpaceVariablesDataKeys)
          }
        },
        { safe: true }
      )
    }
    if (Object.keys(updateData).length === 0) {
      throw new BadRequestException('Nothing to update')
    }
    return await this.spaceVariablesDataModel
      .findByIdAndUpdate(spaceVariablesDataDocumentId, updateData, {
        new: true
      })
      .exec()
  }

  public async copySpaceVariablesDataDoc(
    spaceVariablesDataId: SpaceVariablesDataId
  ) {
    let spaceVariablesDataDocument: SpaceVariablesDataDocument

    if (!spaceVariablesDataId) {
      spaceVariablesDataDocument = new this.spaceVariablesDataModel()
    } else {
      spaceVariablesDataDocument = await this.spaceVariablesDataModel
        .findById(spaceVariablesDataId)
        .exec()
      spaceVariablesDataDocument._id = new ObjectId()
      spaceVariablesDataDocument.isNew = true
      spaceVariablesDataDocument.updatedAt = new Date()
      spaceVariablesDataDocument.createdAt = new Date()
    }

    return spaceVariablesDataDocument.save()
  }

  public async restoreSpaceVariablesData(spaceVariablesData) {
    const newSpaceVariablesData = new this.spaceVariablesDataModel()
    newSpaceVariablesData.data = spaceVariablesData
    newSpaceVariablesData._id = new ObjectId()
    newSpaceVariablesData.updatedAt = new Date()
    newSpaceVariablesData.createdAt = new Date()
    return await newSpaceVariablesData.save()
  }
}

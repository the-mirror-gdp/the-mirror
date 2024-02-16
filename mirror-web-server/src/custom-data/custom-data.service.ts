import { BadRequestException, Injectable } from '@nestjs/common'
import { InjectModel } from '@nestjs/mongoose'
import { keyBy } from 'lodash'
import { Model } from 'mongoose'
import { CustomDataId } from '../util/mongo-object-id-helpers'
import { CreateCustomDataDto } from './dto/custom-data.dto'
import { CustomData, CustomDataDocument } from './models/custom-data.schema'
import flat from 'flat'

@Injectable()
export class CustomDataService {
  constructor(
    @InjectModel(CustomData.name)
    private customDataModel: Model<CustomDataDocument>
  ) {}

  async createCustomData(
    creatorIdUser: string,
    customDataDto: CreateCustomDataDto
  ): Promise<CustomDataDocument> {
    const customDataDoc = new this.customDataModel({
      ...customDataDto,
      creator: creatorIdUser
    })

    return await customDataDoc.save()
  }

  async updateCustomDataAdmin(
    customDataId: CustomDataId,
    patchCustomData?: object,
    removeCustomDataKeys?: CustomDataId[]
  ): Promise<CustomDataDocument> {
    const updateData: any = {}
    if (patchCustomData) {
      updateData.$set = flat({
        data: {
          ...patchCustomData
        }
      })
    }
    if (removeCustomDataKeys) {
      updateData.$unset = updateData.$unset = flat({
        data: {
          ...keyBy(removeCustomDataKeys)
        }
      })
    }
    if (Object.keys(updateData).length === 0) {
      throw new BadRequestException('Nothing to update')
    }
    return await this.customDataModel
      .findByIdAndUpdate(customDataId, updateData, {
        new: true
      })
      .exec()
  }
}

import {
  BadRequestException,
  Injectable,
  NotFoundException
} from '@nestjs/common'
import { InjectModel } from '@nestjs/mongoose'
import { MirrorDBRecord } from './models/mirror-db-record.schema'
import { Model, PipelineStage } from 'mongoose'
import {
  MirrorDBRecordId,
  SpaceId,
  SpaceVersionId,
  UserId
} from '../util/mongo-object-id-helpers'
import { UpdateMirrorDBRecordDto } from './dto/update-mirror-db-record.dto'
import { isMongoId } from 'class-validator'
import { RoleService } from '../roles/role.service'
import { ObjectId } from 'bson'
import { ROLE } from '../roles/models/role.enum'

@Injectable()
export class MirrorDBService {
  constructor(
    @InjectModel(MirrorDBRecord.name)
    private readonly mirrorDBModel: Model<MirrorDBRecord>,
    private readonly roleService: RoleService
  ) {}

  public async getRecordFromMirrorDBBySpaceId(spaceId: SpaceId) {
    if (!isMongoId(spaceId)) {
      throw new BadRequestException(`Invalid spaceId ${spaceId as string}`)
    }

    const mirrorDbRecord = await this.mirrorDBModel.findOne({ space: spaceId })

    if (!mirrorDbRecord) {
      throw new NotFoundException(
        `No MirrorDB record found for space with spaceId ${spaceId as string}`
      )
    }

    return mirrorDbRecord
  }

  public async getRecordFromMirrorDBBySpaceVersionId(
    spaceVersionId: SpaceVersionId
  ) {
    if (!isMongoId(spaceVersionId)) {
      throw new BadRequestException(
        `Invalid spaceVersionId ${spaceVersionId as string}`
      )
    }

    const mirrorDbRecord = await this.mirrorDBModel.findOne({
      spaceVersions: spaceVersionId
    })

    if (!mirrorDbRecord) {
      throw new NotFoundException(
        `No MirrorDB record found for spaceVersion with spaceVersionId ${
          spaceVersionId as string
        }`
      )
    }

    return mirrorDbRecord
  }

  public async getRecordFromMirrorDBById(id: MirrorDBRecordId) {
    if (!isMongoId(id)) {
      throw new BadRequestException(`Invalid id ${id as string}`)
    }

    return await this.mirrorDBModel.findById(id)
  }

  public createNewMirrorDB(spaceId: SpaceId) {
    const newMirrorDBData = new this.mirrorDBModel({ space: spaceId })
    return newMirrorDBData.save()
  }

  public async addSpaceVersionToMirrorDB(
    spaceId: SpaceId,
    spaceVersionId: SpaceVersionId
  ) {
    const updateResult = await this.mirrorDBModel.updateOne(
      { space: spaceId },
      { $push: { spaceVersions: spaceVersionId } }
    )

    if (!updateResult.modifiedCount) {
      throw new NotFoundException(
        `No MirrorDB record found for space with spaceId ${spaceId as string}`
      )
    }

    return spaceVersionId
  }

  public async deleteRecordFromMirrorDBById(id: MirrorDBRecordId) {
    if (!isMongoId(id)) {
      throw new BadRequestException(`Invalid id ${id as string}`)
    }

    const deletionResult = await this.mirrorDBModel.deleteOne({ _id: id })

    if (!deletionResult.deletedCount) {
      throw new NotFoundException(
        `No MirrorDB record found with id ${id as string}`
      )
    }

    return id
  }

  public async updateRecordInMirrorDBByIdWithRoleChecks(
    id: MirrorDBRecordId,
    updateMirrorDBRecordDto: UpdateMirrorDBRecordDto,
    userId: UserId
  ) {
    if (!isMongoId(id)) {
      throw new BadRequestException(`Invalid id ${id as string}`)
    }

    const roleCheck = await this._canUserUpdateMirrorDBRecord(userId, id)

    if (!roleCheck) {
      throw new NotFoundException(
        `No MirrorDB record found with id ${id as string}`
      )
    }

    return await this._updateRecordInMirrorDBById(id, updateMirrorDBRecordDto)
  }

  public async updateRecordInMirrorDBByIdAdmin(
    id: MirrorDBRecordId,
    updateMirrorDBRecordDto: UpdateMirrorDBRecordDto
  ) {
    if (!isMongoId(id)) {
      throw new BadRequestException(`Invalid id ${id as string}`)
    }

    return await this._updateRecordInMirrorDBById(id, updateMirrorDBRecordDto)
  }

  private async _updateRecordInMirrorDBById(
    id: MirrorDBRecordId,
    updateMirrorDBRecordDto: UpdateMirrorDBRecordDto
  ) {
    const updatedRecord = await this.mirrorDBModel.findOneAndUpdate(
      { _id: id },
      updateMirrorDBRecordDto,
      { new: true }
    )

    if (!updatedRecord) {
      throw new NotFoundException(
        `No MirrorDB record found with id ${id as string}`
      )
    }

    return updatedRecord
  }

  private async _canUserUpdateMirrorDBRecord(
    userId: UserId,
    mirrorDBRecordId: MirrorDBRecordId
  ) {
    const pipeline: PipelineStage[] = [
      { $match: { _id: new ObjectId(mirrorDBRecordId) } },
      {
        $lookup: {
          from: 'spaces',
          localField: 'space',
          foreignField: '_id',
          as: 'space'
        }
      },
      { $unwind: '$space' },
      {
        $replaceRoot: { newRoot: '$space' }
      },
      ...this.roleService.getRoleCheckAggregationPipeline(userId, ROLE.MANAGER),
      { $project: { _id: 1 } }
    ]

    const [roleCheckResult] = await this.mirrorDBModel
      .aggregate(pipeline)
      .exec()

    return !!roleCheckResult
  }
}

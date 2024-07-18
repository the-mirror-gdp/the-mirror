import { Injectable, NotFoundException } from '@nestjs/common'
import { InjectModel } from '@nestjs/mongoose'
import { Model } from 'mongoose'
import { CreateMaterialInstanceDto } from './dto/create-material-instance.dto'
import { UpdateMaterialInstanceDto } from './dto/update-material-instance.dto'
import { Space, SpaceDocument } from '../space.schema'
import { MaterialInstance } from './material-instance.schema'
import { ObjectId } from 'mongodb'
import { SpaceId, MaterialInstanceId } from '../../util/mongo-object-id-helpers'

// Example with Postman: https://www.loom.com/share/3e115ba20b2f4e4c9d3aba85f1f4f72e?from_recorder=1&focus_title=1
@Injectable()
export class MaterialInstanceService {
  constructor(
    @InjectModel(Space.name)
    private spaceModel: Model<SpaceDocument>
  ) {}

  async create(
    createMaterialInstanceDto: CreateMaterialInstanceDto
  ): Promise<MaterialInstance> {
    // TODO: update with role checks for the Space
    const newMaterialInstance = {
      ...createMaterialInstanceDto,
      _id: new ObjectId().toString()
    }

    delete newMaterialInstance.spaceId

    const space = await this.spaceModel.findByIdAndUpdate(
      createMaterialInstanceDto.spaceId,
      {
        $push: {
          materialInstances: newMaterialInstance
        }
      }
    )

    if (!space) {
      throw new NotFoundException(`This Space doesn't exist`)
    }

    return newMaterialInstance
  }

  async findOne(spaceId: string, materialInstanceId: string) {
    // TODO: update with role checks for the Space
    const space = await this.spaceModel.findOne({ _id: spaceId }).select({
      materialInstances: { $elemMatch: { _id: materialInstanceId } }
    })

    if (!space) {
      throw new NotFoundException(`This space doesn't exist`)
    }

    const materialInstance = space.materialInstances[0]

    if (!materialInstance) {
      throw new NotFoundException(`This materialInstance doesn't exist`)
    }

    return materialInstance
  }

  async update(
    spaceId: SpaceId,
    materialInstanceId: MaterialInstanceId,
    updateMaterialInstanceDto: UpdateMaterialInstanceDto
  ): Promise<MaterialInstance> {
    // TODO: update with role checks for the Space
    const space = await this.findOne(spaceId, materialInstanceId)

    if (!space) {
      throw new NotFoundException(`This space doesn't exist`)
    }

    const newDoc = await this.spaceModel.findByIdAndUpdate(
      spaceId,
      {
        $set: this._getMaterialInstanceUpdateFields(updateMaterialInstanceDto)
      },
      {
        arrayFilters: [{ 'mi._id': materialInstanceId }],
        new: true,
        select: 'materialInstances'
      }
    )

    return newDoc.materialInstances.find((mi) => mi._id == materialInstanceId) // careful: double equals here works but not triple
  }

  copySpaceMaterialInstancesForSpace(
    materialInstances: MaterialInstance[],
    newSpaceId: SpaceId
  ): any[] {
    const newMaterialInstances = materialInstances.map((object) => {
      return {
        ...object,
        spaceId: newSpaceId.toString()
      }
    })
    return newMaterialInstances
  }

  private _getMaterialInstanceUpdateFields(dto: UpdateMaterialInstanceDto) {
    const updateFields = {}

    for (const key in dto) {
      updateFields[`materialInstances.$[mi].${key}`] = dto[key]
    }

    return updateFields
  }

  async delete(
    spaceId: SpaceId,
    materialInstanceId: MaterialInstanceId
  ): Promise<string> {
    // TODO: update with role checks for the Space
    const space = await this.spaceModel.findByIdAndUpdate(spaceId, {
      $pull: {
        materialInstances: { _id: new ObjectId(materialInstanceId) }
      }
    })

    if (!space) {
      throw new NotFoundException(`This space doesn't exist`)
    }

    return materialInstanceId
  }
}

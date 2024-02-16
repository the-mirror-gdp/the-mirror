import {
  BadRequestException,
  Injectable,
  NotFoundException
} from '@nestjs/common'
import { InjectModel } from '@nestjs/mongoose'
import { Environment, EnvironmentDocument } from './environment.schema'
import { Model, Types } from 'mongoose'
import { UpdateEnvironmentDto } from './dto/update-environment.dto'
import { ObjectId } from 'mongodb'

@Injectable()
export class EnvironmentService {
  constructor(
    @InjectModel(Environment.name)
    private readonly environmentModel: Model<EnvironmentDocument>
  ) {}

  public create() {
    const createdEnvironment = new this.environmentModel()
    return createdEnvironment.save()
  }

  public findOne(id: string) {
    return this.environmentModel.findById(id).exec()
  }

  public update(id: string, dto: UpdateEnvironmentDto) {
    return this.environmentModel
      .findByIdAndUpdate(id, dto, { new: true })
      .exec()
  }

  public async copyFromEnvironment(environmentId: string) {
    let environment: EnvironmentDocument

    if (!environmentId) {
      environment = new this.environmentModel()
    } else {
      environment = await this.environmentModel.findById(environmentId).exec()
      environment._id = new ObjectId()
      environment.isNew = true
      environment.updatedAt = new Date()
      environment.createdAt = new Date()
    }

    return environment.save()
  }

  public remove(id: string) {
    if (!Types.ObjectId.isValid(id)) {
      throw new BadRequestException('ID is not a valid Mongo ObjectID')
    }
    return this.environmentModel
      .findOneAndDelete({ _id: id }, { new: true })
      .exec()
      .then((data) => {
        if (data) {
          return data
        } else {
          throw new NotFoundException()
        }
      })
  }

  public async restoreEnvironment(environment: EnvironmentDocument) {
    environment._id = new ObjectId()
    const newEnvironment = new this.environmentModel(environment)
    newEnvironment.updatedAt = new Date()
    newEnvironment.createdAt = new Date()
    return await newEnvironment.save()
  }
}

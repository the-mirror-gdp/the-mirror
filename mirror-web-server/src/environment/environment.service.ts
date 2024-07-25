import {
  BadRequestException,
  ForbiddenException,
  Inject,
  Injectable,
  NotFoundException,
  forwardRef
} from '@nestjs/common'
import { InjectModel } from '@nestjs/mongoose'
import { Environment, EnvironmentDocument } from './environment.schema'
import { Model, Types } from 'mongoose'
import { UpdateEnvironmentDto } from './dto/update-environment.dto'
import { ObjectId } from 'mongodb'
import { Space, SpaceDocument } from '../space/space.schema'
import {
  SpaceService,
  SpaceServiceType,
  SpaceWithStandardPopulatedProperties
} from '../space/space.service'
import { UserId } from '../util/mongo-object-id-helpers'

@Injectable()
export class EnvironmentService {
  constructor(
    @InjectModel(Environment.name)
    private readonly environmentModel: Model<EnvironmentDocument>,
    @InjectModel(Space.name)
    private spaceModel: Model<SpaceDocument>,
    @Inject(forwardRef(() => SpaceService))
    private readonly spaceService: SpaceServiceType
  ) {}

  public create() {
    const createdEnvironment = new this.environmentModel()
    return createdEnvironment.save()
  }

  public findOne(id: string) {
    return this.environmentModel.findById(id).exec()
  }

  public async findOneWithRolesCheck(id: string, userId: UserId) {
    const environment = await this.environmentModel.findById(id).exec()
    if (!environment) {
      throw new NotFoundException()
    }

    // find the space that is associated with this environment
    const space = await this.spaceModel
      .findOne({ environment: new ObjectId(id) })
      .exec()

    if (!space) {
      throw new NotFoundException()
    }

    // get the space with standard populated properties
    // this is necessary to check if the user has access to the space
    const spaceWithStandardPopulatedProperties =
      await this.spaceService.getSpace(space._id)

    // check if the user has access to the space
    if (
      this.spaceService.canFindWithRolesCheck(
        userId,
        spaceWithStandardPopulatedProperties
      )
    ) {
      return environment
    } else {
      throw new ForbiddenException()
    }
  }

  public update(id: string, dto: UpdateEnvironmentDto) {
    return this.environmentModel
      .findByIdAndUpdate(id, dto, { new: true })
      .exec()
  }

  public async updateWithRolesCheck(
    id: string,
    dto: UpdateEnvironmentDto,
    userId: UserId
  ) {
    const environment = await this.environmentModel.findById(id).exec()
    if (!environment) {
      throw new NotFoundException()
    }

    // find the space that is associated with this environment
    const space = await this.spaceModel
      .findOne({ environment: new ObjectId(id) })
      .exec()

    if (!space) {
      throw new NotFoundException()
    }

    // get the space with standard populated properties
    // this is necessary to check if the user has access to the space
    const spaceWithStandardPopulatedProperties =
      await this.spaceService.getSpace(space._id)

    // check if the user has access to the space
    if (
      this.spaceService.canUpdateWithRolesCheck(
        userId,
        spaceWithStandardPopulatedProperties
      )
    ) {
      return this.environmentModel
        .findByIdAndUpdate(id, dto, { new: true })
        .exec()
    } else {
      throw new ForbiddenException()
    }
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

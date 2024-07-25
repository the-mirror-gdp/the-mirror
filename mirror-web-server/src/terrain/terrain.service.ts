import {
  BadRequestException,
  ForbiddenException,
  Inject,
  Injectable,
  Logger,
  NotFoundException,
  forwardRef
} from '@nestjs/common'
import { InjectModel } from '@nestjs/mongoose'
import { FilterQuery, Model, Types } from 'mongoose'
import { Terrain, TerrainDocument } from './terrain.schema'
import { CreateTerrainDto } from './dto/create-terrain.dto'
import { UpdateTerrainDto } from './dto/update-terrain.dto'
import { FileUploadService } from '../util/file-upload/file-upload.service'
import { ObjectId } from 'mongodb'
import { UserId } from '../util/mongo-object-id-helpers'
import { Space, SpaceDocument } from '../space/space.schema'
import { SpaceService, SpaceServiceType } from '../space/space.service'

@Injectable()
export class TerrainService {
  private readonly logger = new Logger(TerrainService.name)

  constructor(
    @InjectModel(Terrain.name) private terrainModel: Model<TerrainDocument>,
    private readonly fileUploadService: FileUploadService,
    @InjectModel(Space.name) private spaceModel: Model<SpaceDocument>,
    @Inject(forwardRef(() => SpaceService))
    private readonly spaceService: SpaceServiceType
  ) {}

  public create(
    createTerrainDto: CreateTerrainDto & { owner: string }
  ): Promise<TerrainDocument> {
    const created = new this.terrainModel(createTerrainDto)
    return created.save()
  }

  public findAllForUser(userId: string): Promise<TerrainDocument[]> {
    return this.terrainModel
      .find()
      .where({
        owner: userId
      })
      .exec()
  }

  public async findOne(id: string): Promise<TerrainDocument> {
    return await this.terrainModel.findById(id).exec()
  }

  // get terrain with roles check
  public async findOneWithRolesCheck(id: string, userId: UserId) {
    const terrain = await this.findOne(id)

    if (!terrain) {
      throw new NotFoundException()
    }

    // if user is terrain owner, return terrain
    if (terrain?.owner.toString() === userId) {
      return terrain
    }

    // get space that uses this terrain
    const space = await this.spaceModel.findOne({ terrain: terrain._id }).exec()

    if (!space) {
      throw new NotFoundException()
    }

    // get space with populate fields for roles check
    const spaceWithPopuleFiels = await this.spaceService.getSpace(
      space._id.toString()
    )

    // check if user has permission to find terrain
    if (
      !this.spaceService.canFindWithRolesCheck(userId, spaceWithPopuleFiels)
    ) {
      throw new ForbiddenException(
        "You don't have permission to find this terrain"
      )
    }
    return terrain
  }

  public findAllPublic(): Promise<TerrainDocument[]> {
    const filter: FilterQuery<any> = { public: true }
    return this.terrainModel.find(filter).limit(1000).exec()
  }

  public update(
    id: string,
    updateTerrainDto: UpdateTerrainDto
  ): Promise<TerrainDocument> {
    return this.terrainModel
      .findByIdAndUpdate(id, updateTerrainDto, { new: true })
      .exec()
  }

  public async updateWithRolesCheck(
    id: string,
    updateTerrainDto: UpdateTerrainDto,
    userId: UserId
  ) {
    const terrain = await this.findOne(id)

    if (!terrain) {
      throw new NotFoundException()
    }

    // if user is terrain owner, update terrain
    if (terrain?.owner.toString() === userId) {
      return this.update(id, updateTerrainDto)
    }

    // get space that uses this terrain
    const space = await this.spaceModel.findOne({ terrain: terrain._id }).exec()

    if (!space) {
      throw new NotFoundException()
    }

    // get space with populate fields for roles check
    const spaceWithPopuleFiels = await this.spaceService.getSpace(
      space._id.toString()
    )

    // check if user has permission to update terrain
    if (
      !this.spaceService.canUpdateWithRolesCheck(userId, spaceWithPopuleFiels)
    ) {
      throw new ForbiddenException(
        "You don't have permission to update terrain"
      )
    }

    return this.update(id, updateTerrainDto)
  }

  /** Copy existing Terrain or create a new default Terrain if undefined */
  public async copyFromTerrain(terrainId: string, userId: string) {
    let terrain: TerrainDocument

    if (!terrainId) {
      /** Create new terrain if undefined */
      const dto = { owner: userId, name: 'New Default Terrain' }
      terrain = new this.terrainModel(dto)
    } else {
      /** Copy terrain as new Terrain Document */
      terrain = await this.terrainModel.findById(terrainId).exec()
      // if terrain isnt found, just resolve and contimue the copy
      if (terrain) {
        terrain._id = new ObjectId()
        terrain.isNew = true
        terrain.updatedAt = new Date()
        terrain.createdAt = new Date()
      } else {
        return Promise.resolve()
      }
    }

    /** Assign current user as owner */
    terrain.owner = userId as any // check how to do this
    return await terrain.save()
  }

  /** Copy terrain voxel file in GCS to new copied space path */
  public async copyVoxelInGCS(fromId: string, toId: string) {
    const fromPath = `space/${fromId}/terrain/voxels.dat`
    const toPath = `space/${toId}/terrain/voxels.dat`
    try {
      if (process.env.ASSET_STORAGE_DRIVER === 'GCP') {
        await this.fileUploadService.copyFileInBucket(
          process.env.GCS_BUCKET_PUBLIC,
          fromPath,
          toPath
        )
      }

      if (
        !process.env.ASSET_STORAGE_DRIVER ||
        process.env.ASSET_STORAGE_DRIVER === 'LOCAL'
      ) {
        return await this.fileUploadService.copyFileLocal(fromPath, toPath)
      }
    } catch (error: any) {
      /** When no voxel exists, one will be created by godot */
      const message: string = error?.message || 'No error message provided'
      const errorMessage = `Copy voxel failed: ${message}`
      this.logger.warn(errorMessage)
    }
  }

  public remove(id: string): Promise<TerrainDocument> {
    if (!Types.ObjectId.isValid(id)) {
      throw new BadRequestException('ID is not a valid Mongo ObjectID')
    }
    return this.terrainModel
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
}

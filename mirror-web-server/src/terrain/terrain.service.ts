import {
  BadRequestException,
  Injectable,
  Logger,
  NotFoundException
} from '@nestjs/common'
import { InjectModel } from '@nestjs/mongoose'
import { FilterQuery, Model, Types } from 'mongoose'
import { Terrain, TerrainDocument } from './terrain.schema'
import { CreateTerrainDto } from './dto/create-terrain.dto'
import { UpdateTerrainDto } from './dto/update-terrain.dto'
import { FileUploadService } from '../util/file-upload/file-upload.service'
import { ObjectId } from 'mongodb'

@Injectable()
export class TerrainService {
  private readonly logger = new Logger(TerrainService.name)

  constructor(
    @InjectModel(Terrain.name) private terrainModel: Model<TerrainDocument>,
    private readonly fileUploadService: FileUploadService
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

  public findOne(id: string): Promise<TerrainDocument> {
    return this.terrainModel.findById(id).exec()
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
      if (process.env.ASSET_STORAGE_DRIVER === 'LOCAL') {
        return await this.fileUploadService.copyFileLocal(fromPath, toPath)
      }
      await this.fileUploadService.copyFileInBucket(
        process.env.GCS_BUCKET_PUBLIC,
        fromPath,
        toPath
      )
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

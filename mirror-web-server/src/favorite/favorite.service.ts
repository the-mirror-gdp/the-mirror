import { Injectable } from '@nestjs/common'
import { InjectModel } from '@nestjs/mongoose'
import { Model } from 'mongoose'
import { CreateFavoriteDto } from './dto/create-favorite.dto'
import { UpdateFavoriteDto } from './dto/update-favorite.dto'
import { Favorite, FavoriteDocument } from './favorite.schema'

@Injectable()
export class FavoriteService {
  constructor(
    @InjectModel(Favorite.name) private favoriteModel: Model<FavoriteDocument>
  ) {}
  create(createFavoriteDto: CreateFavoriteDto): Promise<FavoriteDocument> {
    const created = new this.favoriteModel(createFavoriteDto)
    return created.save()
  }

  findAllForUser(userId: string): Promise<FavoriteDocument[]> {
    return this.favoriteModel
      .find()
      .where({
        user: userId
      })
      .exec()
  }

  findOne(id: string): Promise<FavoriteDocument> {
    return this.favoriteModel.findById(id).exec()
  }

  update(
    id: string,
    updateFavoriteDto: UpdateFavoriteDto
  ): Promise<FavoriteDocument> {
    return this.favoriteModel
      .findByIdAndUpdate(id, updateFavoriteDto, { new: true })
      .exec()
  }

  remove(id: string): Promise<FavoriteDocument> {
    return this.favoriteModel
      .findOneAndDelete({ _id: id }, { new: true })
      .exec()
  }
}

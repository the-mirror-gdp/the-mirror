import { Injectable, NotFoundException } from '@nestjs/common'
import { InjectModel } from '@nestjs/mongoose'
import { Model } from 'mongoose'
import { CreateBlockDto } from './dto/create-block.dto'
import { UpdateBlockDto } from './dto/update-block.dto'
import { Block, BlockDocument } from './block.schema'

@Injectable()
export class BlockService {
  constructor(
    @InjectModel(Block.name) private blockModel: Model<BlockDocument>
  ) {}
  create(createBlockDto: CreateBlockDto): Promise<BlockDocument> {
    const created = new this.blockModel(createBlockDto)
    return created.save()
  }

  async findOne(id: string): Promise<BlockDocument> {
    const data = await this.blockModel.findById(id).exec()
    if (data) {
      return data
    } else {
      throw new NotFoundException(`Block not found`)
    }
  }

  update(id: string, updateBlockDto: UpdateBlockDto): Promise<BlockDocument> {
    return this.blockModel
      .findByIdAndUpdate(id, updateBlockDto, { new: true })
      .exec()
  }

  remove(id: string): Promise<BlockDocument> {
    return this.blockModel
      .findOneAndDelete({ _id: id })
      .exec() as any as Promise<BlockDocument>
  }
}

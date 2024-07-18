import { Injectable } from '@nestjs/common'
import { InjectModel } from '@nestjs/mongoose'
import { Model } from 'mongoose'
import { CreateGodotServerOverrideConfigDto } from './dto/create-godot-server-override-config.dto'
import {
  GodotServerOverrideConfig,
  GodotServerOverrideConfigDocument
} from './godot-server-override-config.schema'

export type FormattedGodotServerOverrideConfigString = string

@Injectable()
export class GodotServerOverrideConfigService {
  constructor(
    @InjectModel(GodotServerOverrideConfig.name)
    private godotServerOverrideConfigModel: Model<GodotServerOverrideConfigDocument>
  ) {}

  async create(
    dto: CreateGodotServerOverrideConfigDto
  ): Promise<GodotServerOverrideConfigDocument> {
    const created = new this.godotServerOverrideConfigModel(dto)
    return await created.save()
  }

  /**
  * @description This formats the return for what's specifically needed for the server scaler
  * Pseudocode output:
  * [debug]\n
    file_logging/log_path, "./server.log"
  * @date 2023-02-09 12:31
  */
  async findOneFormatted(
    spaceId: string
  ): Promise<FormattedGodotServerOverrideConfigString> {
    const timestampMs = Date.now()
    const doc = await this.findOne(spaceId) // leaving this here for more key-value paths in future

    if (doc) {
      // real doc needs checked
      return `[debug]\nfile_logging/log_path=\"./logs/${spaceId}_${timestampMs}.log\"\n`
    }
    return this.getDefaultFormattedStringForServerLogs(spaceId)
  }

  getDefaultFormattedStringForServerLogs(
    id: string
  ): FormattedGodotServerOverrideConfigString {
    const timestampMs = Date.now()
    return `[debug]\nfile_logging/log_path=\"./logs/${id}_${timestampMs}.log\"\n`
  }

  findOne(id: string): Promise<GodotServerOverrideConfigDocument> {
    return this.godotServerOverrideConfigModel.findById(id).exec()
  }

  remove(id: string): Promise<GodotServerOverrideConfigDocument> {
    return this.godotServerOverrideConfigModel
      .findOneAndDelete({ _id: id })
      .exec()
  }
}

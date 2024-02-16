import { Injectable } from '@nestjs/common'
import { InjectModel } from '@nestjs/mongoose'
import { Model } from 'mongoose'
import { MirrorServerConfig } from './mirror-server-config.schema'

@Injectable()
export class MirrorServerConfigService {
  constructor(
    @InjectModel('MirrorServerConfig')
    private readonly mirrorServerConfigModel: Model<MirrorServerConfig>
  ) {
    this.initConfig()
  }

  /**
   * @description Checks if one exists and adds one if not.
   * @date 2023-08-27 22:44
   */
  async initConfig() {
    const configCount = await this.mirrorServerConfigModel
      .countDocuments()
      .exec()
    if (configCount === 0) {
      const initialConfig = new this.mirrorServerConfigModel({
        gdServerVersion: `${process.env.GD_SERVER_VERSION || '5.3.31'}`
      })
      await initialConfig.save()
    }
  }

  async getConfig() {
    return await this.mirrorServerConfigModel.findOne().exec()
  }

  async setGdServerVersion(gdServerVersion: string) {
    return await this.mirrorServerConfigModel
      .findOneAndUpdate({}, { gdServerVersion: gdServerVersion }, { new: true })
      .exec()
  }
}

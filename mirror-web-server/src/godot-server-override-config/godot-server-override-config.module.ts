import { LoggerModule } from './../util/logger/logger.module'
import { Module } from '@nestjs/common'
import { MongooseModule } from '@nestjs/mongoose'
import { GodotServerOverrideConfigController } from './godot-server-override-config.controller'
import {
  GodotServerOverrideConfig,
  GodotServerOverrideConfigSchema
} from './godot-server-override-config.schema'
import { GodotServerOverrideConfigService } from './godot-server-override-config.service'

/**
 * @description The ServerOverrideConfig module is used to override configs of deployed Godot servers
 * @date 2023-02-09 12:53
 */
@Module({
  imports: [
    LoggerModule,
    MongooseModule.forFeature([
      {
        name: GodotServerOverrideConfig.name,
        schema: GodotServerOverrideConfigSchema
      }
    ])
  ],
  controllers: [GodotServerOverrideConfigController],
  providers: [GodotServerOverrideConfigService],
  exports: [GodotServerOverrideConfigService]
})
export class GodotServerOverrideConfigModule {}

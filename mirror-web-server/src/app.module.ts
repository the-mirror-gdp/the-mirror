require('dotenv').config()

import { Module } from '@nestjs/common'
import { ConfigModule } from '@nestjs/config'
import { join } from 'path'
import { AppController } from './app.controller'
import { CustomDataModule } from './custom-data/custom-data.module'
import { CustomDataService } from './custom-data/custom-data.service'
import { SpaceObjectModule } from './space-object/space-object.module'
import { ScheduleModule } from '@nestjs/schedule'
import { SentryModule } from '@ntegral/nestjs-sentry'
import * as os from 'os'
import { AssetModule } from './asset/asset.module'
import { AuthModule } from './auth/auth.module'
import { BlockModule } from './block/block.module'
import { DatabaseModule } from './database/database.module'
import { EnvironmentModule } from './environment/environment.module'
import { FavoriteModule } from './favorite/favorite.module'
import { FirebaseModule } from './firebase/firebase.module'
import { GodotServerOverrideConfigModule } from './godot-server-override-config/godot-server-override-config.module'
import { GodotGateway } from './godot-server/godot.gateway'
import { RedisModule } from './redis/redis.module'
import { ScriptEntityModule } from './script-entity/script-entity.module'
import { SpaceVariablesDataModule } from './space-variable/space-variables-data.module'
import { SpaceModule } from './space/space.module'
import { StorageModule } from './storage/storage.module'
import { StripeModule } from './stripe/stripe.module'
import { TagModule } from './tag/tag.module'
import { TerrainModule } from './terrain/terrain.module'
import { UserFeedbackModule } from './user-feedback/user-feedback.module'
import { UserGroupModule } from './user-groups/user-group.module'
import { UserModule } from './user/user.module'
import { LoggerModule } from './util/logger/logger.module'
import { NODE_ENV } from './util/node-env.enum'
import { PaginationModule } from './util/pagination/pagination.module'
import { ZoneModule } from './zone/zone.module'
import { MirrorServerConfigModule } from './mirror-server-config/mirror-server-config.module'
import { AnalyticsModule } from './analytics/analytics.module'
import { FileAnalyzingModule } from './util/file-analyzing/file-analyzing.module'
import { CronModule } from './cron/cron.module'
import { MirrorDBModule } from './mirror-db/mirror-db.module'
import { ServeStaticModule } from '@nestjs/serve-static'
import { GodotModule } from './godot-server/godot.module'
import { MixpanelModule } from './mixpanel/mixpanel.module'
import { LoginCodeModule } from './login-code/login-code.module'

const envFromFirebase = process.env.GCP_PROJECT_ID || ''
let env = 'dev'
if (envFromFirebase.includes('prod')) {
  env = 'prod'
} else if (envFromFirebase.includes('staging')) {
  env = 'staging'
} else if (envFromFirebase.includes('dev')) {
  env = 'dev'
}

//override localhost
if (
  os.hostname().includes('local') &&
  process.env.NODE_ENV !== NODE_ENV.PRODUCTION &&
  !process.env.K_REVISION // This is truthy if on cloud run
) {
  env = 'localhost'
}

const imports = [
  ConfigModule.forRoot({ isGlobal: true }),
  LoggerModule,
  GodotServerOverrideConfigModule,
  FirebaseModule.initialize(),
  ScheduleModule.forRoot(),
  CustomDataModule,
  SentryModule.forRoot({
    dsn: process.env.SENTRY_DSN,
    debug: false,
    environment: env,
    release: require('../package.json').version,
    logLevels: ['debug'] //based on sentry.io loglevel,
  }),
  SpaceVariablesDataModule,
  StorageModule,
  RedisModule,
  DatabaseModule,
  AssetModule,
  GodotModule,
  UserModule,
  ZoneModule,
  TerrainModule,
  SpaceObjectModule,
  FavoriteModule,
  UserGroupModule,
  SpaceModule,
  TagModule,
  ScriptEntityModule,
  AuthModule,
  PaginationModule,
  UserFeedbackModule,
  StripeModule.forRoot(process.env.STRIPE_SECRET_KEY, {
    apiVersion: '2022-11-15'
  }),
  EnvironmentModule,
  BlockModule,
  MirrorServerConfigModule,
  FileAnalyzingModule,
  CronModule,
  MirrorDBModule,
  MixpanelModule,
  LoginCodeModule
]

if (
  process.env.POST_HOG_PROJECT_ID &&
  process.env.POST_HOG_PROJECT_API_KEY &&
  process.env.POST_HOG_PERSONAL_API_KEY
) {
  imports.push(AnalyticsModule.initialize())
  console.log('Added AnalyticsModule')
}

if (
  !process.env.ASSET_STORAGE_DRIVER ||
  process.env.ASSET_STORAGE_DRIVER === 'LOCAL'
) {
  console.log(
    'Using local storage, path: ',
    join(__dirname, '../', 'localStorage')
  )
  imports.push(
    ServeStaticModule.forRoot({
      serveRoot: '/assets-storage',
      rootPath: join(__dirname, '../', 'localStorage')
    })
  )
}

const providers: any = [CustomDataService, GodotGateway]

@Module({
  imports,
  controllers: [AppController],
  providers
})
export class AppModule {}

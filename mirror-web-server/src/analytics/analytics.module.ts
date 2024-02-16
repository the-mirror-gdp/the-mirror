import { DynamicModule, Global, Module } from '@nestjs/common'
import { PostHogService } from './post-hog/post-hog.service'
import { PostHogClient } from './post-hog/post-hog.client'

@Global()
@Module({})
export class AnalyticsModule {
  static initialize(): DynamicModule {
    const PostHogProvider = {
      provide: 'POSTHOG',
      useFactory: () => {
        return new PostHogClient(process.env.POST_HOG_PROJECT_API_KEY)
      }
    }

    return {
      module: AnalyticsModule,
      providers: [PostHogProvider, PostHogService],
      exports: [PostHogProvider, PostHogService]
    }
  }
}

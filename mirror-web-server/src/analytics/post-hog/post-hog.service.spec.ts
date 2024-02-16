import { Test, TestingModule } from '@nestjs/testing'
import { PostHogService } from './post-hog.service'
import { PostHogClient } from './post-hog.client'
import { beforeEach, describe, expect, it } from 'vitest'

describe('PostHogService', () => {
  let postHogService: PostHogService

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      imports: [],
      providers: [
        PostHogService,
        {
          provide: 'POSTHOG',
          useFactory: () => {
            return new PostHogClient('test')
          }
        }
      ]
    }).compile()

    postHogService = module.get<PostHogService>(PostHogService)
  })

  it('should be defined', () => {
    expect(postHogService).toBeDefined()
  })
})

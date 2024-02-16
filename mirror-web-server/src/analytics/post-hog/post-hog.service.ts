import { Inject, Injectable } from '@nestjs/common'
import { PostHogClient } from './post-hog.client'
import { HogQLQueryBuilder } from './post-hog-query-builder'
import { IPostHogEvent } from '../abstractions/post-hog-event.abstract'

@Injectable()
export class PostHogService {
  constructor(
    @Inject('POSTHOG')
    private readonly _postHogClient: PostHogClient
  ) {}

  public createQueryBuilder<T>(): HogQLQueryBuilder<T> {
    return new HogQLQueryBuilder(this._postHogClient)
  }

  public captureEvent(event: IPostHogEvent) {
    return this._postHogClient.capture(event)
  }
}

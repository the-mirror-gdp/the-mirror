import { POST_HOG_EVENT_NAME } from '../models/post-hog-event-name.enum'

//Interface for events that will be captured (for polymorphism)
export interface IPostHogEvent {
  distinctId: string
  event: POST_HOG_EVENT_NAME
  properties: unknown
  timestamp: Date
}

//Abstract class for events that will be captured
export abstract class PostHogEventBase<T> {
  distinctId: string
  event: POST_HOG_EVENT_NAME
  properties: T
  timestamp: Date

  constructor(
    distinctId: string,
    event: POST_HOG_EVENT_NAME,
    properties: T,
    timestamp: Date
  ) {
    this.distinctId = distinctId
    this.event = event
    this.properties = properties
    this.timestamp = timestamp
  }
}

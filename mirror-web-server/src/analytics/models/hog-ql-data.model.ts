import { POST_HOG_EVENT_NAME } from './post-hog-event-name.enum'

export class HogQLData<T> {
  uuid: string
  eventName: POST_HOG_EVENT_NAME
  data: T
  timestamp: string
  distinctId: string

  constructor(
    uuid: string,
    eventName: POST_HOG_EVENT_NAME,
    data: T,
    timestamp: string,
    distinctId: string
  ) {
    this.uuid = uuid
    this.eventName = eventName
    this.data = data
    this.timestamp = timestamp
    this.distinctId = distinctId
  }
}

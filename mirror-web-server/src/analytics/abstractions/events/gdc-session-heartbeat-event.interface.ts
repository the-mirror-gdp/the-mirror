import { IPostHogEventMetadata } from '../post-hog-event-metadata.interface'

export interface IGDCSessionHeartbeatEvent extends IPostHogEventMetadata {
  AppMode: string
  godotAppVersion: string
  lastActiveTimestamp: number
  secondsSinceActivity: number
}

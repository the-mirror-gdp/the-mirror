//uuid, eventName, eventData, timestamp, distinctId
export type HogQLEventData = [string, string, string, string, string]
export interface IHogQLResponse {
  results: HogQLEventData[]
}

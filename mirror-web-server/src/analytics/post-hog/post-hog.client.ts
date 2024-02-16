import { PostHog, PostHogOptions } from 'posthog-node'
import { POSTHOG_BASE_URL } from '../constants/posthog.constants'
import axios from 'axios'
import {
  HogQLEventData,
  IHogQLResponse
} from '../abstractions/hog-ql-response.interface'
import { HogQLData } from '../models/hog-ql-data.model'
import { POST_HOG_EVENT_NAME } from '../models/post-hog-event-name.enum'
import winston from 'winston'

export class PostHogClient extends PostHog {
  private readonly _projectId = +process.env.POST_HOG_PROJECT_ID
  private readonly _logger: winston.Logger
  private readonly _postBaseHogUrl = POSTHOG_BASE_URL

  constructor(apiKey: string, options?: PostHogOptions) {
    super(apiKey, options)

    this._logger = winston.createLogger({
      level: 'error',
      format: winston.format.simple(),
      transports: [new winston.transports.Console()]
    })
  }

  public async run<T>(query: string): Promise<HogQLData<T>[]> {
    try {
      const request = await axios.post<IHogQLResponse>(
        `${this._postBaseHogUrl}/api/projects/${this._projectId}/query`,
        { query: { kind: 'HogQLQuery', query } },
        {
          headers: {
            Authorization: `Bearer ${process.env.POST_HOG_PERSONAL_API_KEY}`
          }
        }
      )

      return this._tranform<T>(request.data.results)
    } catch (err) {
      this._logger.log('error', 'PostHog request failed')
      this._logger.log('error', err.message, err)
    }
  }

  private _tranform<T>(response: HogQLEventData[]): HogQLData<T>[] {
    return response.map((r) => {
      const uuid = r[0]
      const eventName = r[1] as POST_HOG_EVENT_NAME
      const data = JSON.parse(r[2])
      const timestamp = r[3]
      const distinctId = r[4]

      return new HogQLData(uuid, eventName, data, timestamp, distinctId)
    })
  }
}

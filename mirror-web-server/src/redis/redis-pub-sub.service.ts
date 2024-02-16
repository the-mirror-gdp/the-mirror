import { Injectable } from '@nestjs/common'
import { createClient } from 'redis'

export class RedisMessage {
  message?: Buffer
  exemptedClientId?: string
}

Injectable()
export class RedisPubSubService {
  private _publisher // 2023-06-23 11:42:58: removing the types for this with the NestJS 10 upgrade. There should be an easy drop-in from the redis package for typescript types, but it isnt' worth figuring out right now since this is seldom used
  public get publisher() {
    return this._publisher
  }
  private _subscriber
  public get subscriber() {
    return this._subscriber
  }

  constructor() {
    // 2023-04-05 17:51:10 not sure why _buildRedisClient is called twice rather than sharing an instance. We should fix, but not worth the time testing right now since it works
    this._publisher = this._buildRedisClient()
    this._subscriber = this._buildRedisClient()
  }

  public publishMessage(channel: string, message: string) {
    this.publisher.publish(channel, message)
  }

  private _buildRedisClient() {
    const REDISHOST = process.env.REDISHOST || '127.0.0.1'
    const REDISPORT = process.env.REDISPORT || '6379'
    const url = `redis://${REDISHOST}:${REDISPORT}`

    const client = createClient({ url })
    // this is called in the constructor and the logger isn't available yet, so using console instead of an injected logger
    client.on('connect', () => {
      console.log('Redis client is connected', RedisPubSubService.name)
    })
    client.on('ready', () => {
      console.log('Redis client is ready')
    })
    client.on('error', (err) =>
      console.error('ERR:REDIS:', err, RedisPubSubService.name)
    )
    console.log(
      'Redis client is attempting to connect to url:' + url,
      RedisPubSubService.name
    )
    client.connect()
    return client
  }
}

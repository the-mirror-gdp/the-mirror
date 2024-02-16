/*
https://docs.nestjs.com/modules
*/

import { Module } from '@nestjs/common'
import { MongooseModule } from '@nestjs/mongoose'

@Module({
  imports: [
    MongooseModule.forRootAsync({
      useFactory: () => {
        let mongoDbUrl = process.env.MONGODB_URL
        // check if override is truthy. If so, replace the db name
        if (process.env.OVERRIDE_DB_NAME) {
          console.log('Replacing DB name due to OVERRIDE_DB_NAME')
          if (mongoDbUrl.includes('mongodb://localhost')) {
            mongoDbUrl = mongoDbUrl.replace(
              'mongodb://localhost:27017/themirror',
              `mongodb://localhost:27017/${process.env.OVERRIDE_DB_NAME}`
            )
          } else {
            mongoDbUrl = mongoDbUrl.replace(
              'mongodb.net/themirror',
              `mongodb.net/${process.env.OVERRIDE_DB_NAME}`
            )
          }
        } else {
          console.log(
            'Not replacing DB name due to no OVERRIDE_DB_NAME present'
          )
        }
        return { uri: mongoDbUrl }
      }
    })
  ],
  controllers: [],
  providers: []
})
export class DatabaseModule {}

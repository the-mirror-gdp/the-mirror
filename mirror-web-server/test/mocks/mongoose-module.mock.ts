import { MongooseModule } from '@nestjs/mongoose'
import { MongoMemoryServer } from 'mongodb-memory-server-core'
import { vi } from 'vitest'

export const MockMongooseClass = vi.fn().mockImplementation(() => {
  return {
    save: vi.fn(),
    findById: vi.fn(),
    findByIdAndUpdate: vi.fn(),
    findOneAndDelete: vi.fn()
  }
})

export const MongooseModuleMock = MongooseModule.forRootAsync({
  useFactory: async () => {
    // This will create an new instance of "MongoMemoryServer" and automatically start it
    const mongod = await MongoMemoryServer.create({
      instance: {
        dbName: 'themirror'
      }
    })
    const uri = mongod.getUri()
    return { uri }
  }
})

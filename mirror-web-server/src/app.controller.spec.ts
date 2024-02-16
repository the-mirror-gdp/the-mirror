import { AppController } from './app.controller'
import { Test, TestingModule } from '@nestjs/testing'

describe('AppController', () => {
  let appController: AppController

  beforeEach(async () => {
    const app: TestingModule = await Test.createTestingModule({
      controllers: [AppController],
      providers: []
    }).compile()

    appController = app.get<AppController>(AppController)
  })

  describe('root', () => {
    it('should return a string"', () => {
      expect(appController.getHello()).toBeDefined()
    })
  })
})

import { HttpModule } from '@nestjs/axios'
import { Test, TestingModule } from '@nestjs/testing'
import { beforeEach, describe, expect, it } from 'vitest'
import { SpaceManagerExternalService } from './space-manager-external.service'
import { MirrorServerConfigService } from '../mirror-server-config/mirror-server-config.service'

describe('ZoneScalerService', () => {
  let service: SpaceManagerExternalService

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        SpaceManagerExternalService,
        { provide: MirrorServerConfigService, useValue: {} }
      ],
      imports: [HttpModule]
    }).compile()

    service = module.get<SpaceManagerExternalService>(
      SpaceManagerExternalService
    )
  })

  it('should be defined', () => {
    expect(service).toBeDefined()
  })
})

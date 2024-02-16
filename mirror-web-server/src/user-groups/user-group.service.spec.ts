import { Test, TestingModule } from '@nestjs/testing'
import { GroupModelStub } from '../../test/stubs/group.model.stub'
import { UserGroupService } from './user-group.service'

describe('UserGroupService', () => {
  let service: UserGroupService

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        UserGroupService,
        {
          provide: 'UserGroupModel',
          useClass: GroupModelStub
        }
      ]
    }).compile()

    service = module.get<UserGroupService>(UserGroupService)
  })

  it('should be defined', () => {
    expect(service).toBeDefined()
  })
})

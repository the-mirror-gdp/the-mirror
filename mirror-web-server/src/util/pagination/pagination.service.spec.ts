import { RoleModule } from './../../roles/role.module'
import { Test, TestingModule } from '@nestjs/testing'
import { PaginationService } from './pagination.service'
import { Model } from 'mongoose'
import { getModelToken } from '@nestjs/mongoose'
import { LoggerModule } from '../logger/logger.module'
import { RoleService } from '../../roles/role.service'
import { RoleModelStub } from '../../../test/stubs/role.model.stub'
import { vi } from 'vitest'

describe('PaginationService', () => {
  let service: PaginationService
  let mockModel: Model<any>

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      imports: [LoggerModule],
      providers: [
        PaginationService,
        {
          provide: getModelToken('UnitTest'),
          useValue: Model
        },
        {
          provide: RoleService,
          useValue: {}
        },
        {
          provide: 'RoleModel',
          useClass: RoleModelStub
        }
      ]
    }).compile()

    service = module.get<PaginationService>(PaginationService)
    mockModel = module.get<Model<any>>(getModelToken('UnitTest'))
  })

  it('should be defined', () => {
    expect(service).toBeDefined()
  })

  describe('getPaginatedQueryResponse', () => {
    const mockFindQuery = (result: any[]) => ({
      skip: () => ({
        limit: () => ({ exec: () => result })
      })
    })
    const mockCountQuery = (count: number) => ({ exec: () => count })

    const setSpies = (find: any[], count: number) => {
      vi.spyOn<any, any>(mockModel, 'find').mockReturnValue(mockFindQuery(find))
      vi.spyOn<any, any>(mockModel, 'count').mockReturnValue(
        mockCountQuery(count)
      )
    }

    it('should return correct pagination data if no pagination provided', async () => {
      setSpies(['1', '2'], 2)
      const mockOptions = { _id: { $in: [] } }

      const result = await service.getPaginatedQueryResponse(
        mockModel,
        mockOptions,
        undefined
      )

      const expected = {
        page: 1,
        perPage: 100,
        total: 2,
        totalPage: 1
      }
      expect(result).toEqual(expect.objectContaining(expected))
    })

    it('should return correct pagination data for "page 2, perPage 2"', async () => {
      setSpies(['1', '2', '3', '4', '5'], 5)
      const mockOptions = { _id: { $in: [] } }
      const mockPagination = { page: 2, perPage: 2 }

      const result = await service.getPaginatedQueryResponse(
        mockModel,
        mockOptions,
        mockPagination
      )

      const expected = {
        page: 2,
        perPage: 2,
        total: 5,
        totalPage: 3
      }
      expect(result).toEqual(expect.objectContaining(expected))
    })

    it('should return correct pagination data for no results', async () => {
      setSpies([], 0)
      const mockOptions = { _id: { $in: [] } }
      const mockPagination = { page: 1, perPage: 1 }

      const result = await service.getPaginatedQueryResponse(
        mockModel,
        mockOptions,
        mockPagination
      )

      const expected = {
        page: 1,
        perPage: 1,
        total: 0,
        totalPage: 0
      }
      expect(result).toEqual(expect.objectContaining(expected))
    })
  })
})

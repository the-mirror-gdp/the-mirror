import { ApiProperty } from '@nestjs/swagger'
import { PipelineStage } from 'mongoose'

export interface IPaginatedResponse<T> extends PaginationInterface {
  data: T[]
}

export class PaginatedResponse implements PaginationInterface {
  // for each extension of this, implement the data: T type. Swagger doesnt support generics, so this is the workaround
  // @ApiProperty()
  // data: T[]
  @ApiProperty()
  page?: number
  @ApiProperty()
  perPage?: number
  @ApiProperty()
  total?: number
  @ApiProperty()
  totalPage?: number
}

export interface PaginationInterface {
  page?: number
  perPage?: number
  total?: number
  totalPage?: number
}

export interface NewPaginationInterface {
  startItem?: number
  numberOfItems?: number
  total?: number
  totalPage?: number
}

export enum SORT_DIRECTION {
  'DESC' = -1,
  'ASC' = 1
}
export interface ISort {
  [key: string]: SORT_DIRECTION
}

export interface IPaginationPipeline<T> {
  paginationPipeline: PipelineStage[]
  paginationData: T
}

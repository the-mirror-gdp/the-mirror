import { PaginationInterface } from './pagination.interface'

const DEFAULT_LIMIT = 100

export class PaginationData implements PaginationInterface {
  constructor({ page = 1, perPage = DEFAULT_LIMIT, totalPage = 1, total = 1 }) {
    // the + is there to shorthand convert to number if a string is passed in.
    this.page = +page
    this.perPage = +perPage
    this.total = +total
    this.totalPage = +totalPage
  }

  public page: number
  public perPage: number
  public total: number
  public totalPage: number
}

export class PaginationDataByStartItem implements PaginationInterface {
  constructor({
    startItem = 1,
    numberOfItems = DEFAULT_LIMIT,
    totalPage = 1,
    total = 1
  }) {
    // the + is there to shorthand convert to number if a string is passed in.
    this.startItem = +startItem
    this.numberOfItems = +numberOfItems
    this.total = +total
    this.totalPage = +totalPage
  }

  public startItem: number
  public numberOfItems: number
  public total: number
  public totalPage: number
}

import { FilterQuery } from 'mongoose'

export abstract class SearchQuery<T> {
  public abstract fields: string[]

  public getSearchFilter(searchQuery: string): FilterQuery<T> {
    return {
      $or: this.fields.map((key) => ({ [key]: new RegExp(searchQuery, 'i') }))
    } as FilterQuery<T>
  }
}

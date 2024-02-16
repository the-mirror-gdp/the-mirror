import { HogQLData } from '../models/hog-ql-data.model'
import { PostHogQueryBuilderPropertiesFilter } from '../models/post-hog-query-builder-filter.model'
import { PostHogClient } from './post-hog.client'

export class HogQLQueryBuilder<T> {
  private _query = ''

  constructor(private readonly _postHogClient: PostHogClient) {}

  public select(fields: string | string[]): HogQLQueryBuilder<T> {
    const fieldList = Array.isArray(fields) ? fields.join(', ') : fields
    this._query += `SELECT ${fieldList} `
    return this
  }

  public from(field: string): HogQLQueryBuilder<T> {
    this._query += `FROM ${field} `
    return this
  }

  public where(
    condition: string,
    propertiesFilter?: PostHogQueryBuilderPropertiesFilter
  ): HogQLQueryBuilder<T> {
    const whereFilter =
      propertiesFilter?.convertToQueryBuilderPropertiesFilter()

    if (whereFilter) {
      this._query += `WHERE ${whereFilter} AND (${condition}) `
    } else {
      this._query += `WHERE ${condition} `
    }

    return this
  }

  public andWhere(condition: string): HogQLQueryBuilder<T> {
    this._query += `AND (${condition}) `
    return this
  }

  public orWhere(condition: string): HogQLQueryBuilder<T> {
    this._query += `OR (${condition}) `
    return this
  }

  public limit(count: number): HogQLQueryBuilder<T> {
    this._query += `LIMIT ${count} `
    return this
  }

  public offset(offset: number): HogQLQueryBuilder<T> {
    this._query += `OFFSET ${offset} `
    return this
  }

  public sort(field: string, order: 'ASC' | 'DESC'): HogQLQueryBuilder<T> {
    this._query += `ORDER BY ${field} ${order} `
    return this
  }

  public getRawQuery() {
    return this._query
  }

  public async execute(): Promise<HogQLData<T>[]> {
    return await this._postHogClient.run<T>(this._query)
  }
}

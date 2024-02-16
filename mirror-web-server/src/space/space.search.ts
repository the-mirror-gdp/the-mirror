import { SearchQuery } from '../util/search-query.base'
import { SpaceDocument } from './space.schema'

export class SpaceSearch extends SearchQuery<SpaceDocument> {
  public fields = ['name', 'tags.search']
}

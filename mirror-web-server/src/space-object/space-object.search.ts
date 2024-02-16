import { SearchQuery } from '../util/search-query.base'
import { SpaceObjectDocument } from './space-object.schema'

export class SpaceObjectSearch extends SearchQuery<SpaceObjectDocument> {
  public fields = ['tags.search', 'name']
}

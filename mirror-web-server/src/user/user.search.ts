import { UserDocument } from './user.schema'
import { SearchQuery } from '../util/search-query.base'

export class UserSearch extends SearchQuery<UserDocument> {
  public fields = ['displayName']
}

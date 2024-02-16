import { SearchQuery } from '../util/search-query.base'
import { AssetDocument } from './asset.schema'
/**
 * @deprecated 2023-03-01 13:24:23 I believe PaginatedSearchAssetDto should be used instead
 */
export class AssetSearch extends SearchQuery<AssetDocument> {
  public fields = ['name', 'tags.search', 'categories']
}

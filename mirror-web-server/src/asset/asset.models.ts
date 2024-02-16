import { ApiResponseProperty } from '@nestjs/swagger'
import { Asset } from './asset.schema'

export class AssetApiResponse extends Asset {
  @ApiResponseProperty()
  _id: string
}
export class AssetUsageApiResponse {
  @ApiResponseProperty()
  numberOfSpacesAssetUsedIn: number
}

export class AssetsMetadataResponse {
  @ApiResponseProperty()
  tags: string[]
  @ApiResponseProperty()
  assetTypes: string[]
  @ApiResponseProperty()
  materialsThirdPartySourceDisplayNames: string[]
}

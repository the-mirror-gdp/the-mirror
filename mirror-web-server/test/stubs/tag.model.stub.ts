import { ObjectId } from 'mongodb'
import { Tag } from '../../src/tag/models/tag.schema'
import { ThirdPartySourceTag } from '../../src/tag/models/third-party-tag.schema'
import { assetManagerUserId } from './asset.model.stub'

type OverrideProperties = 'creator' | 'parentTag' | '_id'
type OverridePropertiesThirdPartySourceTag =
  | OverrideProperties
  | '__t'
  | 'thirdPartySourceTMUserId'
export interface ITagWithIds extends Omit<Tag, OverrideProperties> {
  _id: ObjectId
  creator: string
  parentTag?: string
}
export interface IThirdPartySourceTagWithIds
  extends Omit<ThirdPartySourceTag, OverridePropertiesThirdPartySourceTag> {
  __t: string
  _id: ObjectId
  name: string
  mirrorPublicLibrary?: boolean
  creator: string
  parentTag?: string
  thirdPartySourceTMUserId: string
}

export const mockTagAMirrorPublicLibrary: ITagWithIds = {
  name: 'mockTagAMirrorPublicLibrary',
  _id: new ObjectId('507f1f77bcf86cd799439015'),
  mirrorPublicLibrary: true,
  creator: assetManagerUserId
}

export const mockTagBMirrorPublicLibrary: ITagWithIds = {
  name: 'mockTagBMirrorPublicLibrary',
  _id: new ObjectId('507f1f77bcf86cd799439016'),
  mirrorPublicLibrary: true,
  creator: assetManagerUserId
}

export const mockTagCMirrorPublicLibraryThirdPartySource: IThirdPartySourceTagWithIds =
  {
    __t: 'ThirdPartySourceTag',
    _id: new ObjectId('645174ff8f9544ee52edc2da'),
    name: 'mockTagCMirrorPublicLibraryThirdPartySource',
    mirrorPublicLibrary: true,
    creator: assetManagerUserId,
    thirdPartySourceTMUserId: assetManagerUserId,
    thirdPartySourcePublicDescription: 'thirdPartySourcePublicDescription',
    thirdPartySourceTwitterUrl: 'https://twitter.com/themirrorspace',
    thirdPartySourceHomePageUrl: 'https://themirror.space'
  }

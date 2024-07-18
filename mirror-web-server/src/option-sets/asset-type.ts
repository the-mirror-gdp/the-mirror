export enum ASSET_TYPE {
  PANEL = 'PANEL',
  BOX = 'BOX',
  SPHERE = 'SPHERE',
  MESH = 'MESH',
  IMAGE = 'IMAGE',
  AUDIO = 'AUDIO',
  MATERIAL = 'MATERIAL',
  TEXTURE = 'TEXTURE',
  MAP = 'MAP',
  SCRIPT = 'SCRIPT',
  PACK = 'PACK'
}
export type Type<ASSET_TYPE> = ASSET_TYPE // needed for swc. not sure why: https://github.com/swc-project/swc/issues/5047#issuecomment-1335988073

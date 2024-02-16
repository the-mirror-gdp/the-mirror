export enum BLOCK_TYPE {
  GENERIC = 'GENERIC',
  BEHAVIOR = 'BEHAVIOR',
  TRAIT = 'TRAIT',
  EVENT = 'EVENT'
  // I believe OBJECT shouldn't be here because that's technically separate from a game logic block JDM 2022-12-13 16:41:52
}
export type Type<BLOCK_TYPE> = BLOCK_TYPE // needed for swc. not sure why: https://github.com/swc-project/swc/issues/5047#issuecomment-1335988073

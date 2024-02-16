export enum TERRAIN_MATERIAL {
  MARS = 'mars',
  DESERT = 'desert',
  GRASS = 'grass'
}
export type Type<TERRAIN_MATERIAL> = TERRAIN_MATERIAL // needed for swc. not sure why: https://github.com/swc-project/swc/issues/5047#issuecomment-1335988073

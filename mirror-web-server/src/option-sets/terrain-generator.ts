export enum TERRAIN_GENERATOR {
  Empty = '',
  Flat = 'flat_generator01',
  StandardFastNoiseLight = 'fnl_generator01',
  RollingHills = 'rolling_hills_generator01'
}
export type Type<TERRAIN_GENERATOR> = TERRAIN_GENERATOR // needed for swc. not sure why: https://github.com/swc-project/swc/issues/5047#issuecomment-1335988073

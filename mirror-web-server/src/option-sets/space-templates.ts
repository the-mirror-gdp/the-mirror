export enum SPACE_TEMPLATE {
  MARS = 'mars_template',
  DESERT = 'desert_template',
  GRASS = 'grass_template',
  FLAT = 'flat_template'
}
export type Type<SPACE_TEMPLATE> = SPACE_TEMPLATE // needed for swc. not sure why: https://github.com/swc-project/swc/issues/5047#issuecomment-1335988073

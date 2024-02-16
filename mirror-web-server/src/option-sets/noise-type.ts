export enum NOISE_TYPE {
  TYPE_SIMPLEX_SMOOTH = 1,
  TYPE_SIMPLEX = 0,
  TYPE_CELLULAR = 2,
  TYPE_PERLIN = 3,
  TYPE_VALUE_CUBIC = 4,
  TYPE_VALUE = 5
}
export type Type<NOISE_TYPE> = NOISE_TYPE // needed for swc. not sure why: https://github.com/swc-project/swc/issues/5047#issuecomment-1335988073

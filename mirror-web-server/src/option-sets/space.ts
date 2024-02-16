export enum SPACE_TYPE {
  // keep this style as OPEN_WORLD = 'OPEN_WORLD', and not OPEN_WORLD bc we use Object.values in the Mongoose models
  /**
   * @description Continuous open world without a definite start/stop, like an RPG. Note that we were using OPEN_WORLD as the only enum property to start, so many have this but aren't actually OPEN_WORLD.
   * @date 2023-07-20 16:13
   */
  OPEN_WORLD = 'OPEN_WORLD',

  /**
   * @description a match (e.g. a deathmatch) has set start & stop
   * @date 2023-07-20 16:12
   */
  MATCH = 'MATCH'

  // We'll add more in the future. TODO we also need to break out templates and what comprises what.
}
export type Type<SPACE_TYPE> = SPACE_TYPE // needed for swc. not sure why: https://github.com/swc-project/swc/issues/5047#issuecomment-1335988073

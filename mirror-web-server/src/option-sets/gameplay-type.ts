export enum GAMEPLAY_TYPE {
  PLAYER_SPAWN_POINT = 'PLAYER_SPAWN_POINT',
  OBJECT_SPAWN_POINT = 'OBJECT_SPAWN_POINT'
}
export type Type<GAMEPLAY_TYPE> = GAMEPLAY_TYPE // needed for swc. not sure why: https://github.com/swc-project/swc/issues/5047#issuecomment-1335988073

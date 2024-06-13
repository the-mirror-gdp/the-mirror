/**
 * @description These numbers are so we can add different levels of the hierarchy later. Gives us a lot of wriggle room. I'm using hundreds instead of 10s because we'll eventually allow for user-defined permissions, which could be mean a lot of in-between numbers in the DB
 * Negative number is intentionally blocked, and overrides any "positive" role except OWNER.
 * See Miro for that role architecture: https://miro.com/app/board/uXjVPdtZoUE=/?moveToWidget=3458764550338078699&cot=14
 * @date 2023-03-16 15:14
 */

export enum ROLE {
  OWNER = 1000,

  // can create/read/update/delete, but not edit role permissions
  MANAGER = 700,

  // can create/read, but not update/delete
  CONTRIBUTOR = 400,

  // the user is a provider
  PROVIDER = 150,

  // Entity, e.g. a Space, can be entered/observed
  OBSERVER = 100,

  // Entity will appear in search results, but that's it
  DISCOVER = 50,

  // Entity will not appear in search results. Returns a 404 when someone with NO_ROLE attempts to access
  NO_ROLE = 0,

  // Intentionally blocked; this is different from NO_ROLE. Negative numbers override all positive roles (e.g. a block on a user overrides any other ROLE they have, unless they are an owner)
  BLOCK = -100
}
export type Type<Role> = Role

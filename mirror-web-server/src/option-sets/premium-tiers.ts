/**
 * @description Premium access. Note that users can have MULTIPLE. This is important because we want to continually store whether they were in closed alpha. Plus, even with premium tiers, we'll have some "super premium" users too, enterprise users, etc.
 */
export enum PREMIUM_ACCESS {
  CLOSED_ALPHA = 'CLOSED_ALPHA',

  // Future
  PREMIUM_1 = 'PREMIUM_1',
  PREMIUM_2 = 'PREMIUM_2'
}

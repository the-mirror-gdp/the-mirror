import { User } from '../../user/user.schema'

export interface IZonePopulatedUsers {
  usersCount: number
  servers: Record<
    string,
    {
      usersCount: number
      usersPresent: User[]
    }
  >
  usersPresent: User[]
}

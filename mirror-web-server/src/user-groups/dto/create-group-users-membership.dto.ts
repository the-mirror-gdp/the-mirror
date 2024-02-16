import { GROUP_ROLE } from '../../option-sets/group-users-roles'
import { USER_GROUP_MEMBERSHIP_STATUSES } from '../../option-sets/user-group-membership-statuses'

/**
 * @description Add a member to a create. Technically, this creates a membership document for a user that now belongs to a user group.
 * This is an indepedent collection and not a property on User nor UserGroup since membership could get large
 */
export class CreateUserGroupMembershipDto {
  group: string
  status: USER_GROUP_MEMBERSHIP_STATUSES
  creator: string
  user: string
  role: GROUP_ROLE
  expirationDate: Date
}

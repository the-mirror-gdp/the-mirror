import { USER_GROUP_INVITE_STATUSES } from '../../option-sets/user-group-invite-statuses'

/**
 * @description Request to join a group
 */
export class CreateUserGroupRequestDto {
  group: string
  unlimited: boolean
  used: boolean
  status: USER_GROUP_INVITE_STATUSES
  completed: boolean
  completedDate: Date
  creator: string
  updatedAt: Date
  createdAt: Date
}

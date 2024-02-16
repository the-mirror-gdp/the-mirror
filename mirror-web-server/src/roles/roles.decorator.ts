import { SetMetadata } from '@nestjs/common'
import { ROLE } from './models/role.enum'

// 2023-03-08 10:21:36 TODO rework
export const ROLES_KEY = 'roles'
export const Roles = (...roles: ROLE[]) => SetMetadata(ROLES_KEY, roles)

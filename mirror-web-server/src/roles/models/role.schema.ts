import * as mongoose from 'mongoose'
import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose'
import { ApiProperty } from '@nestjs/swagger'
import { User } from '../../user/user.schema'
import { ROLE } from './role.enum'
import { forOwn } from 'lodash'

export type RoleDocument = Role & Document

/**
* @description This is a Role document that defines roles for a Space.
The important fields are users: Map<string, ROLE> and userGroups: Map<string, ROLE>.
The keys are the user's _id or userGroup's _id, and the value is the ROLE.
Ex:
users: {
  'userId1': ROLE.VIEWER,
  'userId2': ROLE.CONTRIBUTOR,
},
userGroups: {
  'userGroupId1': ROLE.VIEWER,
  'userGroupId2': ROLE.CONTRIBUTOR,
}
* @date 2023-03-28 23:32
*/
@Schema({
  timestamps: true,
  toJSON: {
    virtuals: true
  }
})
export class Role {
  _id: string

  @Prop({
    default: ROLE.MANAGER, // default high permissions for lowest friction to build with friends, but permissions can always be locked down.
    required: true,
    type: () => Number
  })
  @ApiProperty({
    description:
      'The default ROLE to use when nothing is specified for the user. A private Space will have defaultRole be <= 0.'
  })
  defaultRole: number

  @Prop({
    required: true,
    type: Map,
    default: {}
  })
  users: Map<string, ROLE>

  @Prop({
    required: true,
    type: Map,
    default: {}
  })
  userGroups: Map<string, ROLE>

  /**
   * @description Needed since we will allow for user-created Roles. When it's created by TM, we should use the TM Asset Manager account so that the creator User IDs are consistent
   * @date 2023-02-11 18:47
   */
  @Prop({ type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true })
  creator: mongoose.Types.ObjectId

  // virtuals
  // must have this virtual getter (Mongoose virtual). It has to be defined on the schema class but implemented via Schema.methods.userIsOwner = function (userId: string): boolean {...
  userIsOwner: (userId) => boolean
  // virtuals to publicly show user owners without showing the rest
  @ApiProperty({
    type: [String],
    description:
      "A virtual property of owner user IDs. This is optional because it's a virtual"
  })
  owners?: [] // this is optional because it's a virtual, so for tests, it shouldn't be seeded

  /**
   * @description The original thought was a boolean for "anyoneCanDuplicate". However, it's clearn to have a role level required to duplicate, so we'll use a number instead. From a UX perspective, this still allows us to show "Anyone can duplicate" as a boolean, but also allows for future implementations such as "Only Managers Can Duplicate"
   * @date 2023-07-13 22:24
   */
  @Prop({
    required: false,
    default: ROLE.OWNER,
    type: Number
  })
  roleLevelRequiredToDuplicate?: number
}

export const RoleSchema = SchemaFactory.createForClass(Role)

RoleSchema.virtual('public').get(function () {
  return this.defaultRole >= ROLE.OBSERVER
})

RoleSchema.pre('save', function () {
  // set the creator as an owner if the document is new
  if (this.isNew) {
    const creatorId = this.creator as unknown as string
    this.users[creatorId] = ROLE.OWNER
  }
})

// virtual helper property to create an array of owner user IDs
RoleSchema.virtual('owners').get(function () {
  if (Object.keys(this.users).length === 0) {
    return []
  }
  const owners = []
  const users = Object.fromEntries(this.users)
  forOwn(users, (value, key) => {
    if (value === ROLE.OWNER) {
      owners.push(key)
    }
  })
  return owners
})

RoleSchema.methods.userIsOwner = userIsOwnerCheck

/**
 * @description This function is exported to it can be tested
 * @date 2023-04-05 15:15
 */
export function userIsOwnerCheck(userId: string): boolean {
  // ensure userId is not undefined/falsey. undefined===undefined can slip through checks
  if (!userId) {
    return false
  }
  if ((this.users as Map<string, ROLE>).get(userId) === ROLE.OWNER) {
    // individual owner
    return true
  }

  // TODO: implement this once we add groups
  // check groups
  // if (this.userGroups) {
  // go through each user group and get check the ROLE that's granted to that group

  // const groupOwnerUserIds: string[] = this.ownerUserGroup.owners.map((o) =>
  //   o._id.toString()
  // )
  // if (groupOwnerUserIds.includes(userId)) { note that this is a Map now though
  //   return true
  // }
  // }
  return false
}

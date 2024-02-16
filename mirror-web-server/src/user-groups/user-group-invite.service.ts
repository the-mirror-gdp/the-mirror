import { Injectable } from '@nestjs/common'
import { InjectModel } from '@nestjs/mongoose'
import { Model, Types } from 'mongoose'
import { USER_GROUP_INVITE_STATUSES } from '../option-sets/user-group-invite-statuses'
import { CreateUserGroupInviteDto } from './dto/create-group-users-invite.dto'
import {
  UserGroupInviteDocument,
  UserGroupInvite
} from './user-group-invite.schema'

@Injectable()
export class UserGroupInviteService {
  constructor(
    @InjectModel(UserGroupInvite.name)
    private userGroupInviteModel: Model<UserGroupInviteDocument>
  ) {}

  public create(dto: CreateUserGroupInviteDto): Promise<any> {
    //the person its owner or admin?

    // await this.groupUsersModel.find({ group_id : createGroupUserInviteDto.group, owner : { '$in' : [user.id] } })
    const created = new this.userGroupInviteModel(dto)
    return created.save()
  }

  public findOne(id: string): Promise<any> {
    return this.userGroupInviteModel.findById(id).exec()
  }

  public remove(id: string): Promise<any> {
    return this.userGroupInviteModel.findOneAndDelete({ _id: id }).exec()
  }

  public findAllForUser(userId: string): Promise<any> {
    return this.userGroupInviteModel
      .aggregate()
      .append({ $match: { recipient: new Types.ObjectId(userId) } })
      .lookup({
        from: 'usergroups',
        localField: 'group',
        foreignField: '_id',
        as: 'group'
      })
      .unwind({ path: '$group' })
      .exec()
  }
  public findInvitesInGroup(groupId: string): Promise<any> {
    return this.userGroupInviteModel
      .aggregate()
      .append({ $match: { group: new Types.ObjectId(groupId) } })
      .lookup({
        from: 'users',
        localField: 'recipient',
        foreignField: '_id',
        as: 'recipient'
      })
      .unwind({ path: '$recipient' })
      .exec()
  }
  public async aceptInvite(InviteId: string): Promise<any> {
    return await this.userGroupInviteModel
      .findByIdAndUpdate(
        InviteId,
        {
          completed: true,
          status: USER_GROUP_INVITE_STATUSES.INVITE_ACCEPTED
        },
        { new: true }
      )
      .exec()
  }
  public declineInvite(InviteId: string): Promise<any> {
    return this.userGroupInviteModel
      .findByIdAndUpdate(
        InviteId,
        {
          completed: true,
          status: USER_GROUP_INVITE_STATUSES.INVITE_DECLINED
        },
        { new: true }
      )
      .exec()
  }
  public ignoreInvite(InviteId: string): Promise<any> {
    return this.userGroupInviteModel
      .findByIdAndUpdate(
        InviteId,
        { completed: true, status: USER_GROUP_INVITE_STATUSES.INVITE_IGNORED },
        { new: true }
      )
      .exec()
  }
}

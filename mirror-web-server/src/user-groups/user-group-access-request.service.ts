import { Injectable } from '@nestjs/common'
import { InjectModel } from '@nestjs/mongoose'
import { Model } from 'mongoose'
import mongoose from 'mongoose'
import { USER_GROUP_INVITE_STATUSES } from '../option-sets/user-group-invite-statuses'
import { CreateUserGroupRequestDto } from './dto/create-group-users-request.dto'
import {
  UserGroupRequestAccessDocument,
  UserGroupRequestAccess
} from './user-group-access-request.schema'

@Injectable()
export class UserGroupAccessRequestService {
  constructor(
    @InjectModel(UserGroupRequestAccess.name)
    private userGroupRequestAccessModel: Model<UserGroupRequestAccessDocument>
  ) {}

  public create(
    createGroupUsersRequestDto: CreateUserGroupRequestDto
  ): Promise<any> {
    const created = new this.userGroupRequestAccessModel(
      createGroupUsersRequestDto
    )
    return created.save()
  }

  public findOne(id: string): Promise<any> {
    return this.userGroupRequestAccessModel.findById(id).exec()
  }

  public remove(id: string): Promise<any> {
    return this.userGroupRequestAccessModel.findOneAndDelete({ _id: id }).exec()
  }

  public findAllForUser(userId: string): Promise<any> {
    return this.userGroupRequestAccessModel
      .find()
      .where({ recipient: userId })
      .exec()
  }

  public seeRequestAcces(groupId: string): Promise<any> {
    return this.userGroupRequestAccessModel
      .aggregate()
      .append({ $match: { group: new mongoose.Types.ObjectId(groupId) } })
      .lookup({
        from: 'users',
        localField: 'creator',
        foreignField: '_id',
        as: 'creator'
      })
      .unwind({ path: '$creator' })
      .exec()
  }

  public aceptRequest(InviteId: string): Promise<any> {
    return this.userGroupRequestAccessModel
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
  public declineRequest(InviteId: string): Promise<any> {
    return this.userGroupRequestAccessModel
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
  public ignoreRequest(InviteId: string): Promise<any> {
    return this.userGroupRequestAccessModel
      .findByIdAndUpdate(
        InviteId,
        { completed: true, status: USER_GROUP_INVITE_STATUSES.INVITE_IGNORED },
        { new: true }
      )
      .exec()
  }
}

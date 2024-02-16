import { Injectable } from '@nestjs/common'
import { InjectModel } from '@nestjs/mongoose'
import { Model } from 'mongoose'
import mongoose from 'mongoose'
import { GROUP_ROLE } from '../option-sets/group-users-roles'
import {
  UserGroupMembershipDocument,
  UserGroupMembership
} from './user-group-membership.schema'
import { CreateUserGroupMembershipDto } from './dto/create-group-users-membership.dto'

@Injectable()
export class UserGroupMembershipService {
  constructor(
    @InjectModel(UserGroupMembership.name)
    private userGroupMembershipModel: Model<UserGroupMembershipDocument>
  ) {}

  public create(
    createUserGroupMembershipDto: CreateUserGroupMembershipDto
  ): Promise<any> {
    const created = new this.userGroupMembershipModel(
      createUserGroupMembershipDto
    )
    return created.save()
  }

  public findOne(id: string): Promise<any> {
    return this.userGroupMembershipModel.findById(id).exec()
  }

  public remove(id: string): Promise<any> {
    return this.userGroupMembershipModel.findOneAndDelete({ _id: id }).exec()
  }

  public findPublicGroupMembershipForUser(
    userId: string
  ): Promise<UserGroupMembershipDocument[]> {
    return (
      this.userGroupMembershipModel
        .find()
        .where({ user: userId, membershipIsPubliclyVisible: true })
        // TODO add a test such that only name is exposed
        // TODO add a filter
        .populate({
          path: 'group',
          select: ['name', 'publicDescription', 'public']
          // TODO fix this. For some reason, the below code isn't working. Groups with public: false are still being returned. The returned doc is for some reason set to "public": "false" as string false, not boolean false. That could be part of the issue.
          // match: {
          //   public: {
          //     $eq: true
          //   }
          // }
        })
        .exec()
    )
  }

  public findAllForUserViaUserMembership(userId: string): Promise<any> {
    return this.userGroupMembershipModel
      .find({ user: userId })
      .populate('group')
      .exec()
  }

  public findAllForUserWithGroup(userId: string): Promise<any> {
    return this.userGroupMembershipModel.find().where({ user: userId }).exec()
  }

  public async getAllAdminLinks(groupId: string, user: string): Promise<any> {
    return await this.userGroupMembershipModel.find({
      group_id: groupId,
      role: { $in: [GROUP_ROLE.GROUP_OWNER, GROUP_ROLE.GROUP_ADMIN] }
    })
  }

  public async getAllPublicMembersForPublicGroup(
    groupId: string
  ): Promise<UserGroupMembershipDocument[]> {
    return await this.userGroupMembershipModel
      .find({ group: groupId, membershipIsPubliclyVisible: true }) // TODO add a test to ensure private group membership isn't exposed
      .populate('user', {
        role: 1,
        _id: 1,
        displayName: 1
      })
      .exec()
  }

  public async findLeaderShip(groupId: string): Promise<any> {
    return await this.userGroupMembershipModel
      .aggregate()
      .append({
        $match: {
          group: new mongoose.Types.ObjectId(groupId),
          role: {
            $in: [GROUP_ROLE.GROUP_OWNER, GROUP_ROLE.GROUP_ADMIN]
          }
        }
      })
      .lookup({
        from: 'users',
        localField: 'user',
        foreignField: '_id',
        as: 'user'
      })
      .unwind({ path: '$user' })
      .exec()
  }
  public async findOwners(groupId: string): Promise<any> {
    return await this.userGroupMembershipModel
      .aggregate()
      .append({
        $match: {
          group: new mongoose.Types.ObjectId(groupId),
          role: { $in: GROUP_ROLE.GROUP_ADMIN }
        }
      })
      .lookup({
        from: 'users',
        localField: 'user',
        foreignField: '_id',
        as: 'user'
      })
      .unwind({ path: '$user' })
      .exec()
  }

  public async findAllMembers(groupId: string, userId: string): Promise<any> {
    return await this.userGroupMembershipModel.findOne({
      group: groupId,
      user: userId
    })
  }
  public async promoteAdmin(groupId: string, userId: string): Promise<any> {
    const userLinkFound = await this.userGroupMembershipModel.findOne({
      group: groupId,
      user: userId
    })
    return await this.userGroupMembershipModel
      .findByIdAndUpdate(
        userLinkFound._id,
        { role: GROUP_ROLE.GROUP_ADMIN },
        { new: true }
      )
      .exec()
  }
  public async promoteOwner(groupId: string, userId: string): Promise<any> {
    const userLinkFound = await this.userGroupMembershipModel.findOne({
      group: groupId,
      user: userId
    })
    return await this.userGroupMembershipModel
      .findByIdAndUpdate(
        userLinkFound._id,
        { role: GROUP_ROLE.GROUP_OWNER },
        { new: true }
      )
      .exec()
  }
  public async demoteOwner(groupId: string, userId: string): Promise<any> {
    const userLinkFound = await this.userGroupMembershipModel.findOne({
      group: groupId,
      user: userId
    })
    return await this.userGroupMembershipModel
      .findByIdAndUpdate(
        userLinkFound._id,
        { role: GROUP_ROLE.GROUP_ADMIN },
        { new: true }
      )
      .exec()
  }
  public async demoteAdmin(groupId: string, userId: string): Promise<any> {
    const userLinkFound = await this.userGroupMembershipModel.findOne({
      group: groupId,
      user: userId
    })
    return await this.userGroupMembershipModel
      .findByIdAndUpdate(
        userLinkFound._id,
        { role: GROUP_ROLE.MEMBER },
        { new: true }
      )
      .exec()
  }
}

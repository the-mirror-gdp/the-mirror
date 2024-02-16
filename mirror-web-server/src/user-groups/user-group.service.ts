import { Injectable } from '@nestjs/common'
import { InjectModel } from '@nestjs/mongoose'
import { Model, Types } from 'mongoose'
import { CreateUserGroupDto } from './dto/create-group.users.dto'
import { UpdateUserGroupDto } from './dto/update-group.users.dto'
import { UserGroup, UserGroupDocument } from './user-group.schema'

@Injectable()
export class UserGroupService {
  constructor(
    @InjectModel(UserGroup.name)
    private userGroupModel: Model<UserGroupDocument>
  ) {}

  public create(createUserGroupDto: CreateUserGroupDto): Promise<any> {
    const created = new this.userGroupModel(createUserGroupDto)
    return created.save()
  }

  public findOne(id: string): Promise<any> {
    return this.userGroupModel
      .aggregate<UserGroupDocument[]>()
      .append({ $match: { _id: new Types.ObjectId(id) } })
      .lookup({
        from: 'users',
        localField: 'creator',
        foreignField: '_id',
        as: 'creator'
      })
      .unwind({ path: '$creator' })
      .exec()
  }

  public update(
    id: string,
    updateUserGroupDto: UpdateUserGroupDto
  ): Promise<any> {
    return this.userGroupModel
      .findByIdAndUpdate(id, updateUserGroupDto, { new: true })
      .exec()
  }

  public remove(id: string): Promise<any> {
    return this.userGroupModel.findOneAndDelete({ _id: id }).exec()
  }

  /**
   * @description Returns all groups where the user is a creator, user, owner, or moderator
   */
  public findAllForUser(userId: string): Promise<any> {
    return this.userGroupModel
      .find()
      .where({
        $or: [
          {
            creator: { $in: [userId] }
          },
          {
            users: { $in: [userId] }
          },
          {
            owners: { $in: [userId] }
          },
          {
            moderators: { $in: [userId] }
          }
        ]
      })
      .exec()
  }

  public search(searchParams): Promise<any> {
    return this.userGroupModel
      .find({
        [searchParams.filterField]: {
          $regex: new RegExp(searchParams.filterValue),
          $options: 'i'
        }
      })
      .sort({ [searchParams.sortField]: searchParams.sortValue })
      .limit(searchParams.limit)
      .skip(searchParams.skip)
      .exec()
  }

  public removeMember(groupId, idUserRemove): Promise<any> {
    return this.userGroupModel
      .findByIdAndUpdate(
        groupId,
        {
          $pull: {
            users: idUserRemove,
            owners: idUserRemove,
            moderators: idUserRemove
          }
        },
        { new: true }
      )
      .exec()
  }

  public async findGroupsInformation(userLinks): Promise<any> {
    const groupsIds = []
    userLinks.map((userLink) => groupsIds.push(userLink.group))

    return await this.userGroupModel.find({ _id: groupsIds })
  }
}

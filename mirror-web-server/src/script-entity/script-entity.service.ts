import { Injectable } from '@nestjs/common'
import { InjectModel } from '@nestjs/mongoose'
import { Model, PipelineStage } from 'mongoose'
import { CreateScriptEntityDto } from './dto/create-script-entity.dto'
import { UpdateScriptEntityDto } from './dto/update-script-entity.dto'
import { ScriptEntity, ScriptEntityDocument } from './script-entity.schema'
import { UserId } from '../util/mongo-object-id-helpers'
import { UserService } from '../user/user.service'
import { AggregationPipelines } from '../util/aggregation-pipelines/aggregation-pipelines'
import { ObjectId } from 'mongodb'

// Example with Postman: https://www.loom.com/share/3e115ba20b2f4e4c9d3aba85f1f4f72e?from_recorder=1&focus_title=1
@Injectable()
export class ScriptEntityService {
  constructor(
    @InjectModel(ScriptEntity.name)
    private scriptEntityModel: Model<ScriptEntityDocument>,
    private readonly userService: UserService
  ) {}

  async create(
    userId: UserId,
    createScriptEntityDto: CreateScriptEntityDto
  ): Promise<ScriptEntityDocument> {
    const created = new this.scriptEntityModel(createScriptEntityDto)
    const createdScript = await created.save()

    await this.addScriptToUserRecents(userId, createdScript._id)
    return createdScript
  }

  async findOne(id: string): Promise<ScriptEntityDocument> {
    return await this.scriptEntityModel.findById(id).exec()
  }

  async update(
    id: string,
    updateScriptEntityDto: UpdateScriptEntityDto
  ): Promise<ScriptEntityDocument> {
    return await this.scriptEntityModel
      .findByIdAndUpdate(id, updateScriptEntityDto, { new: true })
      .exec()
  }

  async delete(id: string): Promise<ScriptEntityDocument> {
    return await this.scriptEntityModel
      .findOneAndDelete({ _id: id }, { new: true })
      .exec()
  }

  async getRecentScripts(userId: UserId) {
    const userRecents = await this.userService.getUserRecents(userId)
    const scriptsIds = userRecents?.scripts || []

    const pipelineQuery: PipelineStage[] =
      AggregationPipelines.getPipelineForGetByIdOrdered(scriptsIds)

    return await this.scriptEntityModel.aggregate(pipelineQuery)
  }

  async addScriptToUserRecents(userId: UserId, scriptId: string) {
    const userRecents = await this.userService.getUserRecents(userId)
    const scripts = userRecents?.scripts || []

    const existingSpaceIndex = scripts.indexOf(scriptId)

    if (existingSpaceIndex >= 0) {
      scripts.splice(existingSpaceIndex, 1)
    } else if (scripts.length === 10) {
      scripts.pop()
    }

    scripts.unshift(scriptId)

    await this.userService.updateUserRecentScripts(userId, scripts)
  }

  async duplicateScriptsAndScriptInstanceScripts(
    scriptIds: string[],
    scriptInstances: any[]
  ) {
    // array of unique script ids
    const duplicatedScriptIds = [
      ...new Set(
        scriptIds.concat(
          scriptInstances.map((instance) => instance.get('script_id'))
        )
      )
    ]

    const scripts = await this.scriptEntityModel.find({
      _id: { $in: duplicatedScriptIds }
    })

    // array of objects with old and new ids where old id is the key and new id is the value
    const duplicatedScriptsIdsWithNewIds = []
    const duplicatedScripts = scripts.map((script) => {
      const newObjectId = new ObjectId().toString()
      duplicatedScriptsIdsWithNewIds.push({
        [script._id.toString()]: newObjectId
      })
      script._id = newObjectId
      script.id = newObjectId
      return script
    })

    // new scriptIds
    const filterNewScriptIds = duplicatedScriptsIdsWithNewIds
      .filter((obj) => scriptIds.includes(Object.keys(obj)[0]))
      .map((obj) => obj[Object.keys(obj)[0]])

    // scriptInstances with updated scriptIds
    const filterAndUpdatedNewScriptInstances = scriptInstances.map(
      (instance) => {
        duplicatedScriptsIdsWithNewIds.map((el) => {
          const objKey = Object.keys(el)[0]
          if (objKey === instance.get('script_id')) {
            instance.set('script_id', el[objKey])
          }
        })
        return instance
      }
    )

    //save duplicated scripts
    await this.scriptEntityModel.insertMany(duplicatedScripts)
    return {
      scriptIds: filterNewScriptIds,
      scriptInstances: filterAndUpdatedNewScriptInstances
    }
  }

  async duplicateSpaceObjectScripts(spaceObjects: any[]) {
    // array script ids
    const scriptsIds = []

    //get all script ids from spaceObjects.scriptEvents
    spaceObjects.map((spaceObject) => {
      spaceObject.scriptEvents.map((script) => {
        scriptsIds.push(script.script_id)
      })
    })

    const scripts = await this.scriptEntityModel.find({
      _id: { $in: scriptsIds }
    })

    // array of objects with old and new ids where old id is the key and new id is the value
    const duplicatedScriptsIdsWithNewIds = []
    const duplicatedScripts = scripts.map((script) => {
      const newObjectId = new ObjectId().toString()
      duplicatedScriptsIdsWithNewIds.push({
        [script._id.toString()]: newObjectId
      })
      script._id = newObjectId
      script.id = newObjectId
      return script
    })

    //save duplicated scripts
    await this.scriptEntityModel.insertMany(duplicatedScripts)

    // geenerate bulk operations for update spaceObjects
    const bulkOps = []
    for (let i = 0; i < spaceObjects.length; i++) {
      const spaceObject = spaceObjects[i]

      const updatedScriptEvents = []
      spaceObject.scriptEvents.map((script) => {
        duplicatedScriptsIdsWithNewIds.map((el) => {
          const objKey = Object.keys(el)[0]
          if (objKey === script.script_id) {
            script.script_id = el[objKey]
            updatedScriptEvents.push(script)
          }
        })
      })

      const bulkOp = {
        updateOne: {
          filter: { _id: spaceObjects[i]._id },
          update: [
            {
              $set: {
                scriptEvents: updatedScriptEvents
              }
            }
          ]
        }
      }
      bulkOps.push(bulkOp)
    }
    return bulkOps
  }

  async restoreScriptEntities(scriptEntities: Map<string, any>[]) {
    const newScriptIds = []

    const newScriptEntities = scriptEntities.map((script) => {
      const newScript = Object.fromEntries(script)
      const newScriptId = new ObjectId()

      newScriptIds.push({
        [script.get('_id'.toString())]: newScriptId.toString()
      })

      newScript._id = newScriptId
      newScript.id = newScriptId
      return newScript
    })

    await this.scriptEntityModel.insertMany(newScriptEntities)

    return newScriptIds
  }
}

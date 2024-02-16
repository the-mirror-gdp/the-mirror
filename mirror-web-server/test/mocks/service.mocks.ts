import { Provider, Type } from '@nestjs/common'
import { getModelToken } from '@nestjs/mongoose'
import { Model } from 'mongoose'
import { vi } from 'vitest'
import { CreateScriptEntityDto } from '../../src/script-entity/dto/create-script-entity.dto'
import { UpdateScriptEntityDto } from '../../src/script-entity/dto/update-script-entity.dto'
import { ScriptEntityDocument } from '../../src/script-entity/script-entity.schema'
import { MockMongooseClass } from './mongoose-module.mock'

/**
* @description This is used as a convenience to mock many classes in the providers array. It results in:
{
  provide: ZoneService,
  useClass: createViMockClass(ZoneService)
},
{
  provide: SpaceService,
  useClass: createViMockClass(SpaceService)
},
{
  provide: SpaceObjectService,
  useClass: createViMockClass(SpaceObjectService)
}

Then in providers, it can be used as
...getMockClassesForProvidersArray([ZoneService, SpaceService, SpaceObjectService])
* @date 2023-07-03 18:07
*/
export function getMockClassesForProvidersArray(classes: any[]): Provider[] {
  return classes.map((c: any) => {
    return {
      provide: c,
      useValue: createViMockClass(c)
    }
  })
}

export function createViMockClass(targetClass: Type<any>): Type<any> {
  const propertyNames = Object.getOwnPropertyNames(targetClass.prototype)

  for (const propertyName of propertyNames) {
    const propertyValue = targetClass.prototype[propertyName]

    if (typeof propertyValue === 'function') {
      targetClass.prototype[propertyName] = vi.fn()
    }
  }

  return targetClass
}

/**
* @description Similar to the above, this results in
    [{
      provide: getModelToken('Zone'),
      useValue: MockMongooseClass
    },
    {
      provide: getModelToken('Terrain'),
      useValue: MockMongooseClass
    }]
* @date 2023-07-03 18:09
*/
export function getMockMongooseModelsForProvidersArray(
  modelNames: string[] = [
    // The default list here is everything, which will cover most use caes
    'Asset',
    'CustomData',
    'Environment',
    'MapAsset',
    'Material',
    'Role',
    'Space',
    'SpaceObject',
    'SpaceVariable',
    'SpaceVariablesData',
    'SpaceVersion',
    'Terrain',
    'Texture',
    'User',
    'UserAccessKey',
    'UserEntityAction',
    'PurchaseOption'
  ]
): Provider[] {
  return modelNames.map((c: any) => {
    return {
      provide: getModelToken(c),
      useClass: MockMongooseClass
    }
  })
}

/**
 * ScriptEntityService
 */
export class MockScriptEntityService {
  private scriptEntities: ScriptEntityDocument[] = []
  private readonly model: Model<ScriptEntityDocument>

  constructor() {
    this.model = {
      create: vi.fn().mockResolvedValue(null),
      findById: vi.fn().mockImplementation((id: string) => {
        const found = this.scriptEntities.find((entity) => entity._id === id)
        return Promise.resolve(found || null)
      }),
      findByIdAndUpdate: vi
        .fn()
        .mockImplementation((id: string, update: any) => {
          const found = this.scriptEntities.find((entity) => entity._id === id)
          if (found) {
            const updated = { ...found, ...update }
            this.scriptEntities = this.scriptEntities.map((entity) =>
              entity._id === id ? updated : entity
            )
            return Promise.resolve(updated)
          }
          return Promise.resolve(null)
        }),
      findOneAndDelete: vi.fn().mockImplementation((condition: any) => {
        const found = this.scriptEntities.find(
          (entity) => entity._id === condition._id
        )
        if (found) {
          this.scriptEntities = this.scriptEntities.filter(
            (entity) => entity._id !== condition._id
          )
          return Promise.resolve(found)
        }
        return Promise.resolve(null)
      })
    } as unknown as Model<ScriptEntityDocument>
  }

  create(
    createScriptEntityDto: CreateScriptEntityDto
  ): Promise<ScriptEntityDocument> {
    const created: ScriptEntityDocument = {
      _id: (this.scriptEntities.length + 1).toString(),
      ...createScriptEntityDto
    } as ScriptEntityDocument
    this.scriptEntities.push(created)
    return Promise.resolve(created)
  }

  findOne(id: string) {
    return this.model.findById(id)
  }

  update(id: string, updateScriptEntityDto: UpdateScriptEntityDto) {
    return this.model.findByIdAndUpdate(id, updateScriptEntityDto, {
      new: true
    })
  }

  delete(id: string) {
    return this.model.findOneAndDelete({ _id: id })
  }
}

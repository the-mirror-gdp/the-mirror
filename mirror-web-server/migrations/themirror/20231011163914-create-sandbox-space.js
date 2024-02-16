const { ObjectId } = require('mongodb')

const MIGRATION_SCRIPT_NAME = '20231011163914-create-sandbox-space'

const SANDBOX_OWNER_ID = '63d824ca169f17bd92617b57'
const SANDBOX_NAME = 'Public Sandbox'
const SANDBOX_TEMPLATE = 'mars_template'
const SANDBOX_TYPE = 'OPEN_WORLD'

module.exports = {
  async up(db, client) {
    const spacesCollection = db.collection('spaces')
    const spaceVariablesDatasCollection = db.collection('spacevariablesdatas')
    const terrainsCollection = db.collection('terrains')
    const customDatasCollection = db.collection('customdatas')
    const environmentsCollection = db.collection('environments')

    try {
      const { insertedId: spaceVariablesDataId } =
        await spaceVariablesDatasCollection.insertOne(getSpaceVariablesData())

      const { insertedId: terrainId } = await terrainsCollection.insertOne(
        getTerrain()
      )

      const { insertedId: environmentId } =
        await environmentsCollection.insertOne(getEnvironment())

      const { insertedId: customDataId } =
        await customDatasCollection.insertOne(getCustomData())

      await spacesCollection.insertOne(
        getSpace(spaceVariablesDataId, customDataId, environmentId, terrainId)
      )
    } catch (err) {
      console.error('MIGRATION: FAILED TO CREATE SANDBOX', err)
    }
  },

  async down(db, client) {
    const spacesCollection = db.collection('spaces')
    const spaceVariablesDatasCollection = db.collection('spacevariablesdatas')
    const terrainsCollection = db.collection('terrains')
    const customDatasCollection = db.collection('customdatas')
    const environmentsCollection = db.collection('environments')
    const migrationScriptKey = `migrationScript.${MIGRATION_SCRIPT_NAME}`

    try {
      await Promise.all([
        spacesCollection.deleteOne({ [migrationScriptKey]: true }),
        spaceVariablesDatasCollection.deleteOne({
          [migrationScriptKey]: true
        }),
        terrainsCollection.deleteOne({ [migrationScriptKey]: true }),
        customDatasCollection.deleteOne({ [migrationScriptKey]: true }),
        environmentsCollection.deleteOne({ [migrationScriptKey]: true })
      ])
    } catch (err) {
      console.error('MIGRATION: FAILED TO DELETE SANDBOX', err)
    }
  }
}

function getTerrain() {
  return {
    heightRange: 30,
    heightStart: -20,
    seed: 0,
    noiseType: 1,
    material: 'mars',
    generator: 'fnl_generator01',
    positionZ: 0,
    positionY: 0,
    positionX: 0,
    owner: SANDBOX_OWNER_ID,
    name: 'terrain',
    createdAt: new Date(),
    updatedAt: new Date(),
    migrationScript: {
      [MIGRATION_SCRIPT_NAME]: true
    }
  }
}

function getEnvironment() {
  return {
    globalIllumination: false,
    fogColor: [0.1, 0.2, 0.3],
    fogDensity: 0.01,
    fogVolumetric: true,
    fogEnabled: false,
    suns: [],
    sunCount: 1,
    skyBottomColor: [0.1, 0.2, 0.3],
    skyHorizonColor: [0.1, 0.2, 0.3],
    skyTopColor: [0.1, 0.2, 0.3],
    createdAt: new Date(),
    updatedAt: new Date(),
    migrationScript: {
      [MIGRATION_SCRIPT_NAME]: true
    }
  }
}

function getCustomData() {
  return {
    data: {},
    createdAt: new Date(),
    updatedAt: new Date(),
    migrationScript: {
      [MIGRATION_SCRIPT_NAME]: true
    }
  }
}

function getSpaceVariablesData() {
  return {
    data: {},
    createdAt: new Date(),
    updatedAt: new Date(),
    migrationScript: {
      [MIGRATION_SCRIPT_NAME]: true
    }
  }
}

function getRole() {
  return {
    _id: new ObjectId(),
    defaultRole: 400,
    creator: SANDBOX_OWNER_ID,
    users: { [SANDBOX_OWNER_ID]: 1000 },
    userGroups: new Map(),
    migrationScript: {
      [MIGRATION_SCRIPT_NAME]: true
    }
  }
}

function getSpace(
  spaceVariablesDataId,
  customDataId,
  environmentId,
  terrainId
) {
  return {
    name: SANDBOX_NAME,
    role: getRole(),
    customData: customDataId,
    spaceVariablesData: spaceVariablesDataId,
    template: SANDBOX_TEMPLATE,
    creator: new ObjectId(SANDBOX_OWNER_ID),
    type: SANDBOX_TYPE,
    environment: environmentId,
    description: SANDBOX_NAME,
    images: [],
    tags: [],
    tagsV2: [],
    scriptIds: [],
    scriptInstances: [],
    lowerLimitY: -200,
    terrain: terrainId,
    createdAt: new Date(),
    updatedAt: new Date(),
    migrationScript: {
      [MIGRATION_SCRIPT_NAME]: true
    }
  }
}

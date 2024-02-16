const { MongoClient, ObjectId } = require('mongodb')

const MIGRATION_SCRIPT_NAME = '20230704060020-role-to-subdocument' // DO NOT INCLUDE A PERIOD OR ELSE IT WILL NEST THE PROPERTY

const collectionNames = [
  'assets',
  'spaces',
  'userfeedbackcomments',
  'userfeedbackitems'
]

module.exports = {
  async up(db, client) {
    await Promise.all(
      collectionNames.map(async (collectionName) => {
        const entitiesWithRole = await retrieveEntitiesWithRole(
          db,
          collectionName
        )
        console.log(
          `entitiesWithRole: ${collectionName}`,
          entitiesWithRole.length
        )
        return await updateEntitiesWithRole(
          db,
          entitiesWithRole,
          collectionName
        )
      })
    )
  },

  async down(db, client) {
    await Promise.all(
      collectionNames.map(async (collectionName) => {
        const assetsWithRole = await retrieveEntitiesWithRole(
          db,
          collectionName
        )
        return await rollbackEntitiesRoleUpdate(
          db,
          assetsWithRole,
          collectionName
        )
      })
    )
  }
}
async function updateEntitiesWithRole(db, entities, collectionName) {
  console.log(
    `Running updateEntitiesWithRole for collection ${collectionName}...`
  )
  try {
    const roleIds = entities.map((entity) => new ObjectId(entity.role))
    // console.log(`roleIds: `, roleIds)
    const roles = await db
      .collection('roles')
      .find({ _id: { $in: roleIds } })
      .toArray()

    // console.log(`roles: `, roles)
    // console.log(`Starting updates for ${entities.length} entities...`)
    const updatePromises = entities.map(async (entity) => {
      const roleId = new ObjectId(entity.role)
      const role = roles.find((r) => r._id.equals(roleId))
      if (role) {
        entity.role = role
        // console.log(`Updating entity with id ${entity._id}...`)
        const result = await db.collection(collectionName).updateOne(
          { _id: entity._id },
          {
            $set: {
              role: {
                ...role,
                migratedViaScriptAt: new Date(),
                migrationScript: {
                  [`${MIGRATION_SCRIPT_NAME}`]: true
                }
              },
              [`migrationScript.${MIGRATION_SCRIPT_NAME}`]: true
            }
          }
        )
        // console.log(
        //   `Update result for entity with id ${entity._id}: `,
        //   result.result
        // )
        return result
      } else {
        return Promise.resolve()
      }
    })

    await Promise.all(updatePromises)
    console.log(`All updates for ${entities.length} entities completed.`)
  } catch (error) {
    console.error('Error updating entities with role', error)
  }
}

async function retrieveEntitiesWithRole(db, collectionName) {
  try {
    const entities = await db
      .collection(collectionName)
      .find({ role: { $exists: true } })
      .toArray()
    return entities
  } catch (error) {
    console.error(`Error retrieving ${collectionName} with role`, error)
  }
}

// down
async function rollbackEntitiesRoleUpdate(db, entities, collectionName) {
  try {
    return await Promise.all(
      entities.map(async (entity) => {
        const roleId = entity.role._id || entity.role
        if (!roleId) {
          throw new Error('shouldnt be here')
        }
        return await db.collection(collectionName).updateOne(
          { _id: entity._id },
          {
            $set: { role: roleId },
            $unset: {
              [`migrationScript.${MIGRATION_SCRIPT_NAME}`]: true
            }
          }
        )
      })
    )
  } catch (error) {
    console.error(`Error rolling back ${collectionName} role update`, error)
  }
}

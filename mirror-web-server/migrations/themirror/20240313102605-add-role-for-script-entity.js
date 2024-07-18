const mongodb = require('mongodb')
const MIGRATION_SCRIPT_NAME = '20240313102605-add-role-for-script-entity'
module.exports = {
  async up(db, client) {
    const spacesCollection = db.collection('spaces')
    const spacesObjectsCollection = db.collection('spaceobjects')
    const scriptEntityCollection = db.collection('scriptentities')
    const rolesCollection = db.collection('roles')
    const migrationScriptKey = `migrationScript.${MIGRATION_SCRIPT_NAME}`
    const scripts = await scriptEntityCollection.find({}).toArray()
    const bulkOps = []
    const rolesInsertData = []
    for (const script of scripts) {
      const owner = await getScriptOwner(script._id)

      if (owner) {
        const roleId = new mongodb.ObjectId()
        const newRole = {
          _id: roleId,
          defaultRole: 100, //ROLE.OBSERVER
          users: {
            [owner.toString()]: 1000
          },
          userGroups: null,
          createdAt: new Date(),
          updatedAt: new Date(),
          creator: new mongodb.ObjectId(owner.toString()),
          migratedViaScriptAt: new Date(),
          migrationScript: {
            [MIGRATION_SCRIPT_NAME]: true
          }
        }

        // save the role data to insert later
        rolesInsertData.push(newRole)

        bulkOps.push({
          updateOne: {
            filter: { _id: script._id },
            update: [
              {
                $set: {
                  creator: new mongodb.ObjectId(owner.toString()),
                  role: newRole,
                  [migrationScriptKey]: true
                }
              }
            ]
          }
        })
      }
    }

    if (rolesInsertData.length > 0) {
      await rolesCollection.insertMany(rolesInsertData)
    }

    if (bulkOps.length > 0) {
      await scriptEntityCollection.bulkWrite(bulkOps)
    }

    async function getScriptOwner(scriptId) {
      // first check in spaces collection
      const space = await spacesCollection.findOne({
        $or: [
          { scriptIds: scriptId.toString() },
          { 'scriptInstances.script_id': scriptId.toString() }
        ]
      })

      if (space && space.creator) {
        return space.creator
      }

      // then check in space objects collection
      const spaceObject = await spacesObjectsCollection.findOne({
        $or: [
          { 'scriptEvents.script_id': scriptId.toString() },
          { 'scriptEvents.script_id': scriptId }
        ]
      })

      if (spaceObject && spaceObject.space) {
        const spaceFormSpaceObject = await spacesCollection.findOne({
          _id: spaceObject.space
        })

        if (spaceFormSpaceObject) {
          return spaceFormSpaceObject.creator
        }
      }

      return undefined
    }
  },

  async down(db, client) {
    const scriptEntityCollection = db.collection('scriptentities')
    const rolesCollection = db.collection('roles')
    const migrationScriptKey = `migrationScript.${MIGRATION_SCRIPT_NAME}`

    await scriptEntityCollection.updateMany(
      { [migrationScriptKey]: { $exists: true } },
      [{ $unset: ['role', 'creator', migrationScriptKey] }]
    )

    await rolesCollection.deleteMany({
      [migrationScriptKey]: { $exists: true }
    })
  }
}

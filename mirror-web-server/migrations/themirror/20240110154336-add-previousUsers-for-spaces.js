const MIGRATION_SCRIPT_NAME = '20240110154336-add-previousUsers-for-spaces'

// This adds the space creator as a "previous user" to ensure it's traced
module.exports = {
  async up(db, client) {
    const spacesCollection = db.collection('spaces')
    const migrationScriptKey = `migrationScript.${MIGRATION_SCRIPT_NAME}`

    const spacesOwners = await spacesCollection
      .aggregate([{ $project: { _id: 1, creator: 1 } }])
      .toArray()

    const bulkOps = []

    await spacesOwners.forEach((space) => {
      bulkOps.push({
        updateOne: {
          filter: { _id: space._id },
          update: [
            {
              $set: {
                [migrationScriptKey]: true,
                previousUsers: [space.creator]
              }
            }
          ]
        }
      })
    })

    if (bulkOps.length > 0) {
      await spacesCollection.bulkWrite(bulkOps)
    }
  },

  async down(db, client) {
    const spacesCollection = db.collection('spaces')
    const migrationScriptKey = `migrationScript.${MIGRATION_SCRIPT_NAME}`
    await spacesCollection.updateMany(
      { [migrationScriptKey]: { $exists: true } },
      [{ $unset: ['previousUsers', migrationScriptKey] }]
    )
  }
}

const MIGRATION_SCRIPT_NAME =
  '20240321092745-add-creator-for-assets-where-they-do-not-exist'

module.exports = {
  async up(db, client) {
    const assetsCollection = db.collection('assets')
    const migrationScriptKey = `migrationScript.${MIGRATION_SCRIPT_NAME}`

    const assetsWithoutCreator = await assetsCollection
      .find({
        creator: { $exists: false },
        owner: { $exists: true }
      })
      .toArray()

    const bulkOps = []

    for (const asset of assetsWithoutCreator) {
      bulkOps.push({
        updateOne: {
          filter: { _id: asset._id },
          update: [
            {
              $set: {
                creator: asset.owner,
                [migrationScriptKey]: true
              }
            }
          ]
        }
      })
    }

    if (bulkOps.length > 0) {
      await assetsCollection.bulkWrite(bulkOps)
    }
  },

  async down(db, client) {
    const assetsCollection = db.collection('assets')
    const migrationScriptKey = `migrationScript.${MIGRATION_SCRIPT_NAME}`

    await assetsCollection.updateMany(
      { [migrationScriptKey]: { $exists: true } },
      [{ $unset: ['creator', migrationScriptKey] }]
    )
  }
}

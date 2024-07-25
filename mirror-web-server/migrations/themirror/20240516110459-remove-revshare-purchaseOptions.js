const MIGRATION_SCRIPT_NAME = '20240516110459-remove-revshare-purchaseOptions'

module.exports = {
  async up(db, client) {
    const assetsCollection = db.collection('assets')
    const migrationScriptKey = `migrationScript.${MIGRATION_SCRIPT_NAME}`

    const assets = await assetsCollection
      .find({
        'purchaseOptions.type':"MIRROR_REV_SHARE" 
      })
      .toArray()

    const bulkOps = []

    for (const asset of assets) {
      bulkOps.push({
        updateOne: {
          filter: { _id: asset._id },
          update: {
            $pull: { purchaseOptions: { type: "MIRROR_REV_SHARE" } },
            $set: {
              [migrationScriptKey]: true
            }
          }
        }
      })
    }

    if (bulkOps.length) {
      await assetsCollection.bulkWrite(bulkOps)
    }
  },
  async down(db, client) {
    // This migration is irreversible
  }
};

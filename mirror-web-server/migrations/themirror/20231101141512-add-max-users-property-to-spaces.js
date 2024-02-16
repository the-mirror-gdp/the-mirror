const MIGRATION_SCRIPT_NAME = '20231101141512-add-max-users-property-to-spaces'

module.exports = {
  async up(db, client) {
    const spacesCollection = db.collection('spaces')
    const migrationScriptKey = `migrationScript.${MIGRATION_SCRIPT_NAME}`

    await spacesCollection.updateMany(
      {},
      { $set: { maxUsers: 24, [migrationScriptKey]: true } }
    )
  },

  async down(db, client) {
    const spacesCollection = db.collection('spaces')
    const migrationScriptKey = `migrationScript.${MIGRATION_SCRIPT_NAME}`

    await spacesCollection.updateMany({}, [
      { $unset: ['maxUsers', migrationScriptKey] }
    ])
  }
}

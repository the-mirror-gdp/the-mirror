const ROLE = {
  NO_ROLE: 0,
  OBSERVER: 100,
  CONTRIBUTOR: 400,
  MANAGER: 700
}

const BUILD_PERMISSIONS = {
  PRIVATE: 'private',
  OBSERVER: 'observer',
  CONTRIBUTOR: 'contributor',
  MANAGER: 'manager'
}

const MIGRATION_SCRIPT_NAME =
  '20231213144652-move-public-build-permissions-to-db-property'

module.exports = {
  async up(db, client) {
    const spacesCollection = db.collection('spaces')
    const migrationScriptKey = `migrationScript.${MIGRATION_SCRIPT_NAME}`

    await spacesCollection.updateMany({}, [
      {
        $set: {
          publicBuildPermissions: {
            $switch: {
              branches: [
                {
                  case: { $eq: ['$role.defaultRole', ROLE.NO_ROLE] },
                  then: BUILD_PERMISSIONS.PRIVATE
                },
                {
                  case: { $eq: ['$role.defaultRole', ROLE.OBSERVER] },
                  then: BUILD_PERMISSIONS.OBSERVER
                },
                {
                  case: { $eq: ['$role.defaultRole', ROLE.CONTRIBUTOR] },
                  then: BUILD_PERMISSIONS.CONTRIBUTOR
                },
                {
                  case: { $eq: ['$role.defaultRole', ROLE.MANAGER] },
                  then: BUILD_PERMISSIONS.MANAGER
                }
              ],
              default: BUILD_PERMISSIONS.PRIVATE
            }
          },
          [migrationScriptKey]: true
        }
      }
    ])
  },

  async down(db, client) {
    const spacesCollection = db.collection('spaces')
    const migrationScriptKey = `migrationScript.${MIGRATION_SCRIPT_NAME}`

    await spacesCollection.updateMany(
      { [migrationScriptKey]: { $exists: true } },
      [{ $unset: ['publicBuildPermissions', migrationScriptKey] }]
    )
  }
}

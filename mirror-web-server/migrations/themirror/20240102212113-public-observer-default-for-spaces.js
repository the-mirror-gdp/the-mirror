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
  '20240102212113-public-observer-default-for-spaces'

module.exports = {
  async up(db, client) {
    const spacesCollection = db.collection('spaces')
    const migrationScriptKey = `migrationScript.${MIGRATION_SCRIPT_NAME}`

    await spacesCollection.updateMany(
      {
        publicBuildPermissions: BUILD_PERMISSIONS.PRIVATE,
        'role.defaultRole': ROLE.NO_ROLE,
        createdAt: { $gte: new Date('2023-12-16') }
      },
      {
        $set: {
          publicBuildPermissions: BUILD_PERMISSIONS.OBSERVER,
          'role.defaultRole': ROLE.OBSERVER,
          [migrationScriptKey]: true
        }
      }
    )
  },

  async down(db, client) {
    const spacesCollection = db.collection('spaces')
    const migrationScriptKey = `migrationScript.${MIGRATION_SCRIPT_NAME}`

    await spacesCollection.updateMany(
      { [migrationScriptKey]: { $exists: true } },
      [
        {
          $set: {
            publicBuildPermissions: BUILD_PERMISSIONS.PRIVATE,
            'role.defaultRole': ROLE.NO_ROLE,
            [migrationScriptKey]: undefined
          }
        }
      ]
    )
  }
}

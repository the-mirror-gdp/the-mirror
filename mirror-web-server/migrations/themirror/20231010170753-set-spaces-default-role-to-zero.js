const MIGRATION_SCRIPT_NAME = '20231010170753-set-spaces-default-role-to-zero'
const PREVIOUS_DEFAULT_ROLE_KEY_NAME =
  'previousDefaultRole-set-spaces-default-role-to-zero'
const PREVIOUS_ROLE_REQUIRED_LEVEL_TO_DUPLICATE_KEY =
  'previousRoleLevelRequiredToDuplicate-set-spaces-default-role-to-zero'

module.exports = {
  async up(db, client) {
    const spacesCollection = db.collection('spaces')

    const migrationScriptKey = `role.migrationScript.${MIGRATION_SCRIPT_NAME}`
    const previousDefaultRoleKey = `role.migrationScript.${PREVIOUS_DEFAULT_ROLE_KEY_NAME}`
    const previousRoleLevelRequiredToDuplicateKey = `role.migrationScript.${PREVIOUS_ROLE_REQUIRED_LEVEL_TO_DUPLICATE_KEY}`

    const templates = await spacesCollection
      .find(
        {
          'role.defaultRole': { $gte: 100 },
          'role.roleLevelRequiredToDuplicate': { $lte: 100 }
        },
        { projection: { _id: 1 } }
      )
      .toArray()

    const templateIds = templates.map((template) => template._id)

    await spacesCollection.updateMany({ _id: { $nin: templateIds } }, [
      {
        $set: {
          'role.defaultRole': 0,
          [migrationScriptKey]: true,
          [previousDefaultRoleKey]: `$role.defaultRole`
        }
      }
    ])

    await spacesCollection.updateMany({ _id: { $in: templateIds } }, [
      {
        $set: {
          'role.defaultRole': 50,
          'role.roleLevelRequiredToDuplicate': 50,
          isTMTemplate: true,
          [migrationScriptKey]: true,
          [previousDefaultRoleKey]: `$role.defaultRole`,
          [previousRoleLevelRequiredToDuplicateKey]:
            '$role.roleLevelRequiredToDuplicate'
        }
      }
    ])
  },

  async down(db, client) {
    const spacesCollection = db.collection('spaces')

    const migrationScriptKey = `role.migrationScript.${MIGRATION_SCRIPT_NAME}`
    const previousDefaultRoleKey = `role.migrationScript.${PREVIOUS_DEFAULT_ROLE_KEY_NAME}`
    const previousRoleLevelRequiredToDuplicateKey = `role.migrationScript.${PREVIOUS_ROLE_REQUIRED_LEVEL_TO_DUPLICATE_KEY}`

    await spacesCollection.updateMany(
      {
        $and: [
          {
            isTMTemplate: true
          },
          {
            [previousRoleLevelRequiredToDuplicateKey]: { $exists: true }
          }
        ]
      },
      [
        {
          $set: {
            'role.defaultRole': `$${previousDefaultRoleKey}`,
            'role.roleLevelRequiredToDuplicate': `$${previousRoleLevelRequiredToDuplicateKey}`,
            [migrationScriptKey]: '',
            [previousDefaultRoleKey]: ''
          }
        },
        {
          $unset: [
            migrationScriptKey,
            previousDefaultRoleKey,
            'isTMTemplate',
            previousRoleLevelRequiredToDuplicateKey
          ]
        }
      ]
    )

    await spacesCollection.updateMany(
      {
        $and: [
          { [migrationScriptKey]: { $exists: true } },
          { [previousDefaultRoleKey]: { $exists: true } },
          { isTMTemplate: { $exists: false } }
        ]
      },
      [
        {
          $set: {
            'role.defaultRole': `$${previousDefaultRoleKey}`,
            [migrationScriptKey]: '',
            [previousDefaultRoleKey]: ''
          }
        },
        {
          $unset: [
            migrationScriptKey,
            previousDefaultRoleKey,
            'isTMTemplate',
            previousRoleLevelRequiredToDuplicateKey
          ]
        }
      ]
    )
  }
}

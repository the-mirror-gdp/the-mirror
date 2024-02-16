const COLLECTION_NAME = 'assets'
const mongodb = require('mongodb')
// this is used to append to modifictions to also _undo_ the migration
const MIGRATION_SCRIPT_NAME = '20230503025558-asset-roles' // DO NOT INCLUDE A PERIOD OR ELSE IT WILL NEST THE PROPERTY

/**
 * Note on this migration: for a cleaner undo migration (migrate down), I've added a 
 migrationScript: {
  [MIGRATION_SCRIPT_NAME]: true
 }
  property to each created role so that when if it needs to be undone, it can just be via:
{
  $unset: {
    role: 1,
    [`migrationScript.${MIGRATION_SCRIPT_NAME}`]: 1
  }

  This is a good pattern to use for future migrations.
}
 */

// Bug in this migration that needs to be fixed: https://linear.app/the-mirror/issue/ENG-2054/fix-undefined-role-bug-use-a-migration

module.exports = {
  async up(db, client) {
    // get collections: source
    const sourceCollection = db.collection(COLLECTION_NAME)

    // get all docs that we're going to update
    const sourceDocs = await sourceCollection
      .find({
        role: {
          $exists: false
        }
      })
      .toArray()

    const scriptRunDate = new Date()

    // run the loop to update docs
    await Promise.all(
      sourceDocs.map(async (sourceDoc, index) => {
        // create a role for this doc
        const roleId = new mongodb.ObjectId()
        const insertData = {
          _id: roleId,
          defaultRole: 100, //ROLE.OBSERVER
          users: {
            // Jared's mistake: || sourceDoc.owner was added this *after* the migration was applied. https://github.com/the-mirror-megaverse/mirror-server/commit/f46660cb0ff9881f0612c779da33a06b112faf3d
            [sourceDoc.creator || sourceDoc.owner]: 1000
          },
          userGroups: {},
          createdAt: new Date(),
          updatedAt: new Date(),
          // Jared's mistake: || sourceDoc.owner was added this *after* the migration was applied. https://github.com/the-mirror-megaverse/mirror-server/commit/f46660cb0ff9881f0612c779da33a06b112faf3d
          creator: new mongodb.ObjectId(sourceDoc.creator || sourceDoc.owner),
          migratedViaScriptAt: new Date(),
          migrationScript: {
            [MIGRATION_SCRIPT_NAME]: true
          }
        }
        // insert the role doc
        await db.collection('roles').insertOne(insertData)
        // update the doc with the new role we created
        await sourceCollection.findOneAndUpdate(
          {
            _id: sourceDoc._id
          },
          {
            $set: {
              role: new mongodb.ObjectId(roleId),
              updatedAt: scriptRunDate,
              [`migrationScript.${MIGRATION_SCRIPT_NAME}`]: true
            }
          }
        )
        console.log(`updated ${COLLECTION_NAME} doc:` + sourceDoc._id)
      })
    )
  },

  async down(db, client) {
    // get collections: source
    const sourceCollection = db.collection(COLLECTION_NAME)

    // get all docs that we're going to update
    const sourceDocs = await sourceCollection
      .find({
        [`migrationScript.${MIGRATION_SCRIPT_NAME}`]: true
      })
      .toArray()

    const roleIdsToRemove = []
    await Promise.all(
      // remove .role on all docs
      sourceDocs.map(async (sourceDoc, index) => {
        roleIdsToRemove.push(sourceDoc.role.id)
        await sourceCollection.findOneAndUpdate(
          {
            _id: sourceDoc._id
          },
          {
            $unset: {
              role: 1,
              [`migrationScript.${MIGRATION_SCRIPT_NAME}`]: 1
            }
          }
        )
        console.log(`updated ${COLLECTION_NAME} doc:` + sourceDoc._id)
      })
    )
    // remove role docs
    await db.collection('roles').deleteMany({
      [`migrationScript.${MIGRATION_SCRIPT_NAME}`]: true
    })
    console.log(`removed roles docs`)
  }
}

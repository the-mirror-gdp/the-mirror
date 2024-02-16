const COLLECTION_NAME = 'spaces'
const mongodb = require('mongodb')
// this is used to append to modifictions to also _undo_ the migration
const MIGRATION_SCRIPT_NAME =
  '20230605224354-add-space-variables-data-to-spaces' // DO NOT INCLUDE A PERIOD OR ELSE IT WILL NEST THE PROPERTY

/**
 * Note on this migration: for a cleaner undo migration (migrate down), I've added a 
 migrationScript: {
  [MIGRATION_SCRIPT_NAME]: true
 }
  property to each created role so that when if it needs to be undone, it can just be via:
{
  $unset: {
    [`migrationScript.${MIGRATION_SCRIPT_NAME}`]: 1
  }
  This is a good pattern to use for future migrations.
}
 */

module.exports = {
  async up(db, client) {
    // get collections: source
    const sourceCollection = db.collection(COLLECTION_NAME)

    // get all docs that we're going to update
    const sourceDocs = await sourceCollection
      .find({
        spaceVariablesData: {
          $exists: false
        }
      })
      .toArray()

    console.log('sourceDocs', sourceDocs.length);
    const scriptRunDate = new Date()

    // run the loop to update docs
    await Promise.all(
      sourceDocs.map(async (sourceDoc, index) => {
        // create a spaceVariablesData for this doc
        const spaceVariablesDataId = new mongodb.ObjectId()
        let insertData = {
          _id: spaceVariablesDataId,
          data: {},
          createdAt: new Date(),
          updatedAt: new Date(),
          migratedViaScriptAt: new Date(),
          migrationScript: {
            [MIGRATION_SCRIPT_NAME]: true
          }
        }
        try {
          await db.collection('spacevariablesdatas').insertOne(insertData)
          console.log(`WILL update ${COLLECTION_NAME} doc:` + sourceDoc._id)
          // update the doc with the new spaceVariablesData we created
          await sourceCollection.findOneAndUpdate(
            {
              _id: sourceDoc._id
            },
            {
              $set: {
                spaceVariablesData: spaceVariablesDataId,
                updatedAt: scriptRunDate,
                [`migrationScript.${MIGRATION_SCRIPT_NAME}`]: true
              }
            }
          )
        } catch (error) {
          console.error(error)
        }
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

    await Promise.all(
      // remove .spacevariablesdatas on all docs
      sourceDocs.map(async (sourceDoc, index) => {
        await sourceCollection.findOneAndUpdate(
          {
            _id: sourceDoc._id
          },
          {
            $unset: {
              spaceVariablesData: 1,
              [`migrationScript.${MIGRATION_SCRIPT_NAME}`]: 1
            }
          }
        )
        console.log(`updated ${COLLECTION_NAME} doc:` + sourceDoc._id)
      })
    )
    // remove spacevariablesdatas docs
    await db.collection('spacevariablesdatas').deleteMany({
      [`migrationScript.${MIGRATION_SCRIPT_NAME}`]: true
    })
    console.log(`removed spacevariablesdatas docs`)
  }
}

var path = require('path')
const collectionNames = [
  'spaces'
]
const migrationScriptName = path.basename(__filename)
const mongodb = require('mongodb')

module.exports = {
  async up(db, client) {
    await Promise.all(
      // loop through all collections
      collectionNames.map(async (collectionName) => {

        // get collections: source
        const sourceCollection = db.collection(collectionName)

        // get all docs that we're going to update
        const sourceDocs = await sourceCollection
          .find({
            customData: {
              $exists: false
            }
          })
          .toArray()

        const scriptRunDate = new Date()
        await Promise.all(
          sourceDocs.map(async (sourceDoc, index) => {
            const customDataId = new mongodb.ObjectId()
            let insertData = {
              _id: customDataId,
              data: {},
              createdAt: new Date(),
              updatedAt: new Date(),
              creator: new mongodb.ObjectId(sourceDoc._id), // asset manager
              migrationScriptName: migrationScriptName,
              migratedViaScriptAt: new Date()
            }
            await db.collection('customdatas').insertOne(insertData)
            await sourceCollection.findOneAndUpdate(
              {
                _id: sourceDoc._id
              },
              {
                $set: {
                  customData: customDataId,
                  updatedAt: scriptRunDate
                }
              }
            )
            console.log(`updated ${collectionName} doc:` + sourceDoc._id)
          })
        )
      })
    )


  },

  async down(db, client) {


  }
}

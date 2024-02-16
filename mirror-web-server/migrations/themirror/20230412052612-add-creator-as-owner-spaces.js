const collectionNames = [
  'spaces'
]
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
            role: {
              $exists: true
            }
          })
          .toArray()
        const rolesCursor = await db.collection('roles').find()
        await rolesCursor.forEach(console.log);

        await Promise.all(
          sourceDocs.map(async (sourceDoc, index) => {
            if (!sourceDoc.role || !sourceDoc.creator) {
              return
            }

            await db.collection('roles').updateOne(
              {
                _id: sourceDoc.role
              },
              {
                $set: {
                  [`users.${sourceDoc.creator}`]: 1000
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

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
              $exists: false
            }
          })
          .toArray()

        const scriptRunDate = new Date()
        await Promise.all(
          sourceDocs.map(async (sourceDoc, index) => {
            const roleId = new mongodb.ObjectId()
            let insertData = {
              _id: roleId,
              defaultRole: 700,
              users: {
                [sourceDoc.creator]: 1000
              },
              userGroups: {},
              createdAt: new Date(),
              updatedAt: new Date(),
              creator: new mongodb.ObjectId(sourceDoc.creator),
              migratedViaScriptAt: new Date()
            }
            await db.collection('roles').insertOne(insertData)
            await sourceCollection.findOneAndUpdate(
              {
                _id: sourceDoc._id
              },
              {
                $set: {
                  role: new mongodb.ObjectId(roleId),
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

        const roleIdsToRemove = []
        await Promise.all(
          // remove .role on all docs
          sourceDocs.map(async (sourceDoc, index) => {
            roleIdsToRemove.push(sourceDoc.role._id)
            await sourceCollection.findOneAndUpdate(
              {
                _id: sourceDoc._id
              },
              {
                $unset: {
                  role: 1,
                  updatedAt: 1
                }
              }
            )
            console.log(`updated ${collectionName} doc:` + sourceDoc._id)
          })

        )
        // remove role docs
        await db.collection('roles').deleteMany({
          role: {
            $in: roleIdsToRemove
          }
        })
        console.log(`removed roles docs`)
      })
    )

  }
}

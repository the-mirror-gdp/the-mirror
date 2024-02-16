const collectionNames = [
  'spaceobjects'
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
            objectTextureSize: {
              $exists: true
            }
          })
          .toArray()

        await Promise.all(

          sourceDocs.map(async (sourceDoc, index) => {

            const sizeArray = [sourceDoc.objectTextureSize, sourceDoc.objectTextureSize, sourceDoc.objectTextureSize]
            await sourceCollection.updateOne(
              {
                _id: sourceDoc._id
              },
              {
                $set: {
                  objectTextureSizeV2: sizeArray
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
            objectTextureSizeV2: {
              $exists: true
            }
          })
          .toArray()

        await Promise.all(

          sourceDocs.map(async (sourceDoc, index) => {

            await sourceCollection.updateOne(
              {
                _id: sourceDoc._id
              },
              {
                $unset: {
                  objectTextureSizeV2: 1
                }
              }
            )
            console.log(`updated unset ${collectionName} doc:` + sourceDoc._id)
          })

        )
      })
    )

  }
}

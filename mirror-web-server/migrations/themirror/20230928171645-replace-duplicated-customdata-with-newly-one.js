const { ObjectId } = require('mongodb')
const SPACE_COLLECTION_NAME = 'spaces'
const CUSTOM_DATAS_COLLECTION_NAME = 'customdatas'
const MIGRATION_SCRIPT_NAME =
  '20230928171645-replace-duplicated-customdata-with-newly-one'
const ORIGINAL_CUSTOM_DATA_ID_KEY_NAME =
  'originalCustomDataId-replace-duplicated-customdata-with-newly-one'

module.exports = {
  async up(db, client) {
    const spacesCollection = db.collection(SPACE_COLLECTION_NAME)
    const customDataCollection = db.collection(CUSTOM_DATAS_COLLECTION_NAME)

    //Find the ids of the recurring CustomData
    const duplicateCustomDataIds = await spacesCollection
      .aggregate([
        {
          $group: {
            _id: '$customData',
            count: { $sum: 1 }
          }
        },
        {
          $match: {
            count: { $gt: 1 }
          }
        }
      ])
      .toArray()

    //For each repeated id we find the original customData document with this id
    for (const duplicateId of duplicateCustomDataIds) {
      const originalCustomData = await customDataCollection.findOne({
        _id: duplicateId._id
      })

      //Retrieve all the Spaces that has repeated customData id, except the first one, to preserve the original.
      const spacesWithDuplicateCustomData = await spacesCollection
        .find({
          customData: duplicateId._id
        })
        .skip(1)
        .toArray()

      //Create an array of promises to create a new customData entity and update the corresponding space with the new id
      const updateSpacesPromises = spacesWithDuplicateCustomData.map(
        async (space) => {
          const newCustomData = getNewCustomData(
            originalCustomData.data,
            space.creator,
            originalCustomData._id
          )

          await customDataCollection.insertOne(newCustomData)

          await spacesCollection.updateOne(
            { _id: space._id },
            { $set: { customData: newCustomData._id } }
          )
        }
      )

      try {
        await Promise.all(updateSpacesPromises)
      } catch (err) {
        console.error('Failed to update custom data', err)
      }
    }
  },

  async down(db, client) {
    const spacesCollection = db.collection(SPACE_COLLECTION_NAME)
    const customDataCollection = db.collection(CUSTOM_DATAS_COLLECTION_NAME)

    //Retrieve all spaces
    const spacesToUpdate = await spacesCollection.find().toArray()

    //Update space to have original customData id from migrationScript
    const updateSpacesPromises = spacesToUpdate.map(async (space) => {
      const customData = await customDataCollection.findOne({
        _id: space.customData
      })

      const originalId =
        customData?.migrationScript?.[ORIGINAL_CUSTOM_DATA_ID_KEY_NAME]

      if (originalId) {
        await spacesCollection.updateOne(
          { _id: space._id },
          { $set: { customData: originalId } }
        )
      }
    })

    try {
      await Promise.all(updateSpacesPromises)
    } catch (err) {
      console.error('Failed to update custom data', err)
    }

    //Delete all customData that were migrated by this script
    const migrationScriptKey = `migrationScript.${MIGRATION_SCRIPT_NAME}`
    await customDataCollection.deleteMany({
      [migrationScriptKey]: true
    })
  }
}

//Returns new customData
function getNewCustomData(data, creatorId, originalId) {
  return {
    _id: new ObjectId(),
    data,
    createdAt: new Date(),
    updatedAt: new Date(),
    creator: new ObjectId(creatorId),
    migratedViaScriptAt: new Date(),
    migrationScript: {
      [MIGRATION_SCRIPT_NAME]: true,
      [ORIGINAL_CUSTOM_DATA_ID_KEY_NAME]: originalId
    }
  }
}

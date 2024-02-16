const { ObjectId } = require('mongodb')
const SPACE_COLLECTION_NAME = 'spaces'
const SPACE_VARIABLES_DATA_COLLECTION_NAME = 'spacevariablesdatas'
const MIGRATION_SCRIPT_NAME =
  '20230928114146-replace-duplicated-spacevars-with-newly-one'
const ORIGINAL_SPACE_VARIABLE_DATA_ID_KEY_NAME =
  'originalSpaceVariableDataId-replace-duplicated-spacevars-with-newly-one'

module.exports = {
  async up(db, client) {
    const spacesCollection = db.collection(SPACE_COLLECTION_NAME)
    const spaceVariableDataCollection = db.collection(
      SPACE_VARIABLES_DATA_COLLECTION_NAME
    )

    //Find the ids of the recurring SpaceVariablesData
    const duplicateSpaceVariablesDataIds = await spacesCollection
      .aggregate([
        {
          $group: {
            _id: '$spaceVariablesData',
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

    //For each repeated id we find the original spaceVariableData document with this id
    for (const duplicateId of duplicateSpaceVariablesDataIds) {
      const originalSpaceVariablesData =
        await spaceVariableDataCollection.findOne({
          _id: duplicateId._id
        })

      //Retrieve all the Spaces that has repeated spaceVariableData id, except the first one, to preserve the original.
      const spacesWithDuplicateSpaceVariablesData = await spacesCollection
        .find({
          spaceVariablesData: duplicateId._id
        })
        .skip(1)
        .toArray()

      //Create an array of promises to create a new SpaceVariablesData entity and update the corresponding space with the new id
      const updateSpacesPromises = spacesWithDuplicateSpaceVariablesData.map(
        async (space) => {
          const newSpaceVariablesData = getNewSpaceVariableData(
            originalSpaceVariablesData.data,
            originalSpaceVariablesData._id
          )

          await spaceVariableDataCollection.insertOne(newSpaceVariablesData)

          await spacesCollection.updateOne(
            { _id: space._id },
            { $set: { spaceVariablesData: newSpaceVariablesData._id } }
          )
        }
      )

      try {
        await Promise.all(updateSpacesPromises)
      } catch (err) {
        console.error('Failed to update space variables data', err)
      }
    }
  },

  async down(db, client) {
    const spacesCollection = db.collection(SPACE_COLLECTION_NAME)
    const spaceVariableDataCollection = db.collection(
      SPACE_VARIABLES_DATA_COLLECTION_NAME
    )

    //Retrieve all spaces
    const spacesToUpdate = await spacesCollection.find().toArray()

    //Update space to have original SpaceVariableData id from migrationScript
    const updateSpacesPromises = spacesToUpdate.map(async (space) => {
      const spaceVariablesData = await spaceVariableDataCollection.findOne({
        _id: space.spaceVariablesData
      })

      const originalId =
        spaceVariablesData?.migrationScript?.[
          ORIGINAL_SPACE_VARIABLE_DATA_ID_KEY_NAME
        ]

      if (originalId) {
        await spacesCollection.updateOne(
          { _id: space._id },
          { $set: { spaceVariablesData: originalId } }
        )
      }
    })

    try {
      await Promise.all(updateSpacesPromises)
    } catch (err) {
      console.error('Failed to update space variables data', err)
    }

    //Delete all spaceVariableData that were migrated by this script
    const migrationScriptKey = `migrationScript.${MIGRATION_SCRIPT_NAME}`
    await spaceVariableDataCollection.deleteMany({
      [migrationScriptKey]: true
    })
  }
}

//Returns new SpaceVariableData
function getNewSpaceVariableData(data, originalId) {
  return {
    _id: new ObjectId(),
    data,
    createdAt: new Date(),
    updatedAt: new Date(),
    migratedViaScriptAt: new Date(),
    migrationScript: {
      [MIGRATION_SCRIPT_NAME]: true,
      [ORIGINAL_SPACE_VARIABLE_DATA_ID_KEY_NAME]: originalId
    }
  }
}

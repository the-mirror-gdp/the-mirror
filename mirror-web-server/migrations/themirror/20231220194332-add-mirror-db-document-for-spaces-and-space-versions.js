const MIGRATION_SCRIPT_NAME =
  '20231220194332-add-mirror-db-document-for-spaces-and-space-versions'

const MIGRATION_SCRIPT_KEY = `migrationScript.${MIGRATION_SCRIPT_NAME}`

module.exports = {
  async up(db, client) {
    const spacesCollection = db.collection('spaces')
    const mirrorDBRecordsCollection = db.collection('mirrordbrecords')

    // {spaceId: ObjectId, spaceVersionsIds: [ObjectId]}[]
    const aggregationResult = await spacesCollection
      .aggregate([
        { $addFields: { spaceId: { $toString: '$_id' } } },
        {
          $lookup: {
            from: 'spaceversions',
            localField: 'spaceId',
            foreignField: 'spaceId',
            as: 'spaceVersionsData'
          }
        },
        {
          $project: {
            _id: 0,
            spaceId: { $toObjectId: '$spaceId' },
            spaceVersionsIds: '$spaceVersionsData._id'
          }
        }
      ])
      .toArray()

    const bulkOps = []

    aggregationResult.forEach((data) => {
      bulkOps.push({
        insertOne: {
          document: {
            space: data.spaceId,
            spaceVersions: data.spaceVersionsIds,
            recordData: {},
            migrationScript: {
              [MIGRATION_SCRIPT_NAME]: true
            }
          }
        }
      })
    })

    if (bulkOps.length > 0) {
      await mirrorDBRecordsCollection.bulkWrite(bulkOps)
    }
  },

  async down(db, client) {
    const mirrorDBRecordsCollection = db.collection('mirrordbrecords')

    await mirrorDBRecordsCollection.deleteMany({
      [MIGRATION_SCRIPT_KEY]: true
    })
  }
}

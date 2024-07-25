const MIGRATION_SCRIPT_NAME = '20240408063332-remove-GLB-endings-on-uploads'

module.exports = {
  async up(db, client) {
    const assetsCollection = db.collection('assets')
    const migrationScriptKey = `migrationScript.${MIGRATION_SCRIPT_NAME}`

    const assets = await assetsCollection
      .find({
        name: {
          $regex: 'GLB|glb|GLTF|glft|OBJ',
          $options: 'i'
        }
      })
      .toArray()

    const bulkkOps = []
    for (const asset of assets) {
      const newName = asset.name
        .replace(' .glb', '')
        .replace('.glb', '')
        .replace(' (glb)', '')
        .replace('(glb)', '')
        .replace(' (GLB)', '')
        .replace('(GLB)', '')
        .replace(' GLB1', '')
        .replace(' GLB2', '')
        .replace(' (GLTF)', '')
        .replace('(GLTF)', '')
        .replace(' GLTF', '')
        .replace('GLTF', '')
        .replace(' glft', '')
        .replace('.glft', '')
        .replace('glft', '')
        .replace(' (OBJ)', '')

      bulkkOps.push({
        updateOne: {
          filter: { _id: asset._id },
          update: {
            $set: {
              name: newName,
              [migrationScriptKey]: true
            }
          }
        }
      })
    }

    if (bulkkOps.length) {
      await assetsCollection.bulkWrite(bulkkOps)
    }
  },

  async down(db, client) {
    const assetsCollection = db.collection('assets')
    const migrationScriptKey = `migrationScript.${MIGRATION_SCRIPT_NAME}`

    const assets = await assetsCollection
      .find({
        [migrationScriptKey]: true
      })
      .toArray()

    const bulkkOps = []
    for (const asset of assets) {
      const newName = asset.name + ' (GLB)'
      bulkkOps.push({
        updateOne: {
          filter: { _id: asset._id },
          update: {
            $set: {
              name: newName,
              [migrationScriptKey]: false
            }
          }
        }
      })
    }

    if (bulkkOps.length) {
      await assetsCollection.bulkWrite(bulkkOps)
    }
  }
}

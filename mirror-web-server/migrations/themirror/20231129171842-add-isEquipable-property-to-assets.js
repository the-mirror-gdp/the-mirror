const path = require('path')
const Piscina = require('piscina')
const os = require('os')
const { ObjectId } = require('mongodb')

const piscina = new Piscina({
  filename: path.resolve(
    __dirname,
    '..',
    '..',
    'workers/add-isEquipable-propery-to-assets.worker.js'
  )
})

const MIGRATION_SCRIPT_NAME =
  '20231129171842-add-isEquipable-property-to-assets'
const MIGRATION_SCRIPT_KEY = `migrationScript.${MIGRATION_SCRIPT_NAME}`

const NUM_OF_CORES = os.cpus().length

module.exports = {
  async up(db, client) {
    const assetsCollection = db.collection('assets')

    const idsAndUrlsOfAssets = await assetsCollection
      .aggregate([
        {
          $match: { currentFile: { $exists: true, $regex: /\.(glb|gltf)$/i } }
        },
        { $project: { currentFile: 1 } }
      ])
      .toArray()

    const CHUNK_SIZE = Math.ceil(idsAndUrlsOfAssets.length / NUM_OF_CORES)

    const chunks = []
    for (let i = 0; i < idsAndUrlsOfAssets.length; i += CHUNK_SIZE) {
      let chunk = idsAndUrlsOfAssets.slice(i, i + CHUNK_SIZE)
      chunk = chunk.map((asset) => ({
        _id: asset._id.toString(),
        currentFile: asset.currentFile,
        isGLB: asset.currentFile.toLowerCase().endsWith('.glb')
      }))

      chunks.push(chunk)
    }

    // Array of arrays of asset ids from each worker
    const workersResult = await Promise.all(
      chunks.map((chunk) => piscina.run(chunk))
    )

    const idsToUpdate = workersResult.flat().map((id) => new ObjectId(id))

    await assetsCollection.updateMany(
      { _id: { $in: idsToUpdate } },
      { $set: { [MIGRATION_SCRIPT_KEY]: true, isEquipable: true } }
    )
  },

  async down(db, client) {
    const assetsCollection = db.collection('assets')

    await assetsCollection.updateMany({ [MIGRATION_SCRIPT_KEY]: true }, [
      { $unset: [MIGRATION_SCRIPT_KEY, 'isEquipable'] }
    ])
  }
}

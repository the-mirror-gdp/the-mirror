// eslint-disable-next-line @typescript-eslint/no-var-requires
const fetch = require('node-fetch')
const { NodeIO } = require('@gltf-transform/core')
const { PassThrough, pipeline } = require('stream')
const { parser } = require('stream-json')
const { pick } = require('stream-json/filters/Pick')
const { streamValues } = require('stream-json/streamers/StreamValues')
const { Extension } = require('@gltf-transform/core')
const { ALL_EXTENSIONS } = require('@gltf-transform/extensions')

class MirrorEquipableExtension extends Extension {
  extensionName = 'MIRROR_equipable'
  static EXTENSION_NAME = 'MIRROR_equipable'

  read() {
    return this
  }

  write() {
    return this
  }
}

async function fetchBuffer(url) {
  const response = await fetch(url)
  return await response.buffer()
}

async function isAssetEquipable(buffer, isGLB) {
  if (isGLB) {
    try {
      const io = new NodeIO()
      const glbDocument = await io
        .registerExtensions([MirrorEquipableExtension, ...ALL_EXTENSIONS])
        .readBinary(buffer)
      return glbDocument
        .getRoot()
        .listExtensionsUsed()
        .some(
          (ext) => ext.extensionName === MirrorEquipableExtension.EXTENSION_NAME
        )
    } catch (err) {
      console.log(err)
      return false
    }
  }

  const bufferStream = new PassThrough()
  bufferStream.end(buffer)

  return new Promise((resolve) =>
    pipeline(
      bufferStream,
      parser(),
      pick({ filter: 'extensions' }),
      streamValues(),
      (err) => {
        if (err) {
          console.log('GLTF Processing Pipeline failed.', err)
        } else {
          console.log('GLTF Processing Pipeline completed.')
        }
      }
    )
      .on('data', ({ value }) => {
        if (value.MIRROR_equipable) {
          resolve(true)
        }
      })
      .on('error', () => resolve(false))
      .on('end', () => {
        resolve(false)
      })
  )
}

//chunk: {_id: ObjectId, currentFile: string, isGLB: boolean}[]
module.exports = async function processAsset(chunk) {
  const workerIdsToUpdate = []

  for (let i = 0; i < chunk.length; i++) {
    const asset = chunk[i]
    console.log(`Iteration ${i} of ${chunk.length}`)

    const buffer = await fetchBuffer(asset.currentFile)
    const isEquipable = await isAssetEquipable(buffer, asset.isGLB)

    if (isEquipable) {
      workerIdsToUpdate.push(asset._id)
    }
  }

  return workerIdsToUpdate
}

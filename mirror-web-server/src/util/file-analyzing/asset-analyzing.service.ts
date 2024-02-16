import { BadRequestException, Inject, Injectable, Logger } from '@nestjs/common'
import { pipeline, PassThrough } from 'stream'
import { parser } from 'stream-json'
import { pick } from 'stream-json/filters/Pick'
import StreamValues, { streamValues } from 'stream-json/streamers/StreamValues'
import FilterBase from 'stream-json/filters/FilterBase'
import { Document, Extension, NodeIO } from '@gltf-transform/core'
import { MirrorEquipableExtension } from './glb-extensions/mirror-equipable.extension'
import { GLBAnalyzingHandler } from './abstractions/glb-analyzing-handler.type'
import { FILE_ANALYZING_MIMETYPES } from './enums/file-analyzing-mimetypes.enum'
import { ALL_EXTENSIONS } from '@gltf-transform/extensions'

@Injectable()
export class AssetAnalyzingService {
  constructor(
    private readonly logger: Logger,
    @Inject('NODE_IO') private readonly nodeIo: NodeIO
  ) {}

  public async isAssetEquipable(
    assetFile: Express.Multer.File
  ): Promise<boolean> {
    switch (assetFile.mimetype) {
      case FILE_ANALYZING_MIMETYPES.GLB:
        return await this.isGLBAssetEquippable(assetFile)
      case FILE_ANALYZING_MIMETYPES.GLTF:
        return await this.isGLTFAssetEquippable(assetFile)
      default:
        return false
    }
  }

  private async isGLBAssetEquippable(
    glbAssetFile: Express.Multer.File
  ): Promise<boolean> {
    return await this.getGLBAnalyzingPipeline(
      glbAssetFile,
      (glbDocument: Document) =>
        glbDocument
          .getRoot()
          .listExtensionsUsed()
          .some(
            (asset) =>
              asset.extensionName === MirrorEquipableExtension.EXTENSION_NAME
          ),
      [MirrorEquipableExtension, ...ALL_EXTENSIONS]
    )
  }

  private async isGLTFAssetEquippable(
    gltfAssetFile: Express.Multer.File
  ): Promise<boolean> {
    try {
      return await new Promise((resolve, reject) => {
        this.getGLTFAnalyzingPipeline(gltfAssetFile, {
          filter: 'extensions'
        })
          .on('data', ({ value }) => {
            if (value.MIRROR_equipable) {
              resolve(true)
            }
          })
          .on('error', (err) => reject(err))
          .on('end', () => {
            resolve(false)
          })
      })
    } catch (err) {
      throw new BadRequestException('Invalid GLTF file')
    }
  }

  private getGLTFAnalyzingPipeline(
    gltfAssetFile: Express.Multer.File,
    filter: FilterBase.FilterOptions
  ): StreamValues {
    const bufferStream = new PassThrough()
    bufferStream.end(gltfAssetFile.buffer)

    return pipeline(
      bufferStream,
      parser(),
      pick(filter),
      streamValues(),
      (err: Error) => {
        if (err) {
          this.logger.error('GLTF Processing Pipeline failed.', err.stack)
        } else {
          this.logger.log('GLTF Processing Pipeline completed.')
        }
      }
    )
  }

  private async getGLBAnalyzingPipeline(
    glbAssetFile: Express.Multer.File,
    processingHandler: GLBAnalyzingHandler,
    extensions: (typeof Extension)[] = []
  ): Promise<boolean> {
    try {
      const glbDocument = await this.nodeIo
        .registerExtensions(extensions)
        .readBinary(glbAssetFile.buffer)

      return await processingHandler(glbDocument)
    } catch (err) {
      this.logger.error('GLB Processing Pipeline failed.', err.stack)
      throw new BadRequestException('Invalid GLB file')
    }
  }
}

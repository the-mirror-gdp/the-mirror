import { storage as firebaseStorage } from 'firebase-admin'
import {
  File,
  GetFilesResponse,
  MakeFilePublicResponse,
  PredefinedAcl
} from '@google-cloud/storage'
import { HttpException, Inject, Injectable, forwardRef } from '@nestjs/common'
import { FileUploadInterface } from './file-upload.interface'
import { FileUploadDto } from './dto/file-upload.dto'
import * as fs from 'fs'
import { String } from 'lodash'
import { DownloadResponse, Storage } from '@google-cloud/storage'
import { AssetService, AssetServiceType } from '../../asset/asset.service'
import { ASSET_TYPE } from '../../option-sets/asset-type'
import { ASSET_MANAGER_UID } from '../../mirror-server-config/asset-manager-uid'
import * as path from 'path'

interface StreamFinishResponse {
  data: any // undefined on success - can we remove this?
  fileObject: File
}

@Injectable()
export class FileUploadService implements FileUploadInterface {
  constructor(
    @Inject(forwardRef(() => AssetService))
    private readonly assetService: AssetServiceType // circular dependency fix. The suffixed -Type type is used to solve circular dependency issue with swc https://github.com/swc-project/swc/issues/5047#issuecomment-1302444311
  ) {}

  private readonly mimeTypeFileMap = {
    'image/webp': '.webp',
    'image/svg+xml': '.svg',
    'image/png': '.png',
    'image/jpeg': '.jpg',
    'image/gif': '.gif',
    'image/bmp': '.bmp',
    'image/tiff': '.tiff',
    'image/x-exr': '.exr',
    'model/gltf-binary': '.glb',
    'model/gltf+json': '.gltf',
    'model/mibm': '.mibm',
    'application/scene-binary': '.pck',
    'audio/ogg': '.ogg',
    'audio/mpeg': '.mp3',
    'audio/wav': '.wav',
    'script/gdscript': '.gd',
    'script/mirror-visual-script+json': '.vs.json',
    'application/json': 'json'
  }

  public async uploadFilePublic({ file, path }: FileUploadDto) {
    if (!file) {
      throw new HttpException('File upload error: File not provided', 400)
    }

    try {
      const pathWithFileType = `${path}${this._getFileTypeEnding(
        file.mimetype
      )}`

      // If we're using local asset storage, we'll just save the file to the local storage
      if (process.env.ASSET_STORAGE_DRIVER === 'LOCAL') {
        console.log('Uploading file to local storage')
        await this.uploadFileLocal(file, pathWithFileType)
        return {
          publicUrl: process.env.ASSET_STORAGE_URL + pathWithFileType
        }
      }

      await this.streamFile(
        process.env.GCS_BUCKET_PUBLIC,
        pathWithFileType,
        file,
        'publicRead'
      )
      return {
        publicUrl: `${process.env.GCP_BASE_PUBLIC_URL}/${pathWithFileType}`
      }
    } catch (error: any) {
      const message: string = error?.message
      throw new HttpException(`File upload error: ${message}`, 400)
    }
  }

  // This is mocked up based on old implementation
  // We currently have no definition on how private asset uploads should work
  public async uploadFilePrivate({ file, path }: FileUploadDto) {
    if (!file) {
      throw new HttpException('File upload error: File not provided', 400)
    }

    try {
      const pathWithFileType = `${path}${this._getFileTypeEnding(
        file.mimetype
      )}`

      // If we're using local asset storage, we'll just save the file to the local storage
      if (process.env.ASSET_STORAGE_DRIVER === 'LOCAL') {
        await this.uploadFileLocal(file, pathWithFileType)
        return { relativePath: pathWithFileType }
      }

      await this.streamFile(
        process.env.GCS_BUCKET,
        pathWithFileType,
        file,
        'private'
      )

      return { relativePath: pathWithFileType }
    } catch (error: any) {
      const message: string = error?.message
      throw new HttpException(`File upload error: ${message}`, 400)
    }
  }

  public async uploadThumbnail({ file, path }: FileUploadDto) {
    if (!file) {
      throw new HttpException('File upload error: File not provided', 400)
    }

    try {
      const thumbnailPath = path + this._getFileTypeEnding(file.mimetype)

      // If we're using local asset storage, we'll just save the file to the local storage
      if (process.env.ASSET_STORAGE_DRIVER === 'LOCAL') {
        await this.uploadFileLocal(file, thumbnailPath)
        return {
          publicUrl: process.env.ASSET_STORAGE_URL + thumbnailPath
        }
      }

      await this.streamFile(
        process.env.GCS_BUCKET_PUBLIC,
        thumbnailPath,
        file,
        'publicRead' // we do want the thumbnail to be public by default. We may modify this in the future though to be more sophisticated
      )
      return {
        publicUrl: `${process.env.GCP_BASE_PUBLIC_URL}/${thumbnailPath}`
      }
    } catch (error: any) {
      const message: string = error?.message
      throw new HttpException(`File upload error: ${message}`, 400)
    }
  }

  public copyFileInBucket(
    bucketName: string,
    fromPath: string,
    toPath: string
  ) {
    const storage = firebaseStorage()
    const destination = storage.bucket(bucketName).file(toPath)
    const options = { predefinedAcl: 'publicRead' }
    return storage
      .bucket(bucketName)
      .file(fromPath)
      .copy(destination, options) as Promise<any> // conflicting types issue
  }

  // the file location is this (starting from root of bucket): <userid>/assets/<assetid>/<fileid.[jpg|png|jpeg|gif|etc]>
  public async streamFile(
    bucketName: string,
    relativePath: string,
    file: Express.Multer.File,
    acl: PredefinedAcl = 'publicRead'
  ): Promise<StreamFinishResponse> {
    return await this.streamData(
      bucketName,
      relativePath,
      file.mimetype,
      file.buffer,
      acl
    )
  }

  public async streamData(
    bucketName: string,
    relativePath: string,
    mimeType: string,
    buffer: Buffer,
    acl: PredefinedAcl = 'publicRead'
  ): Promise<StreamFinishResponse> {
    return await new Promise<StreamFinishResponse>((resolve, reject) => {
      const storage = firebaseStorage()
      const theRemoteFile = storage
        .bucket(bucketName)
        .file(relativePath) as unknown as File // conflicting types issue when typed as File (GCS ServiceObject)
      const stream = theRemoteFile.createWriteStream({
        metadata: {
          contentType: mimeType
        },
        predefinedAcl: acl,
        resumable: false
      })

      stream.on('error', (err) => reject(err))
      stream.on('finish', (data) =>
        resolve({
          data: data,
          fileObject: theRemoteFile
        })
      )
      stream.end(buffer)
    })
  }

  public async getFiles(
    bucketName: string,
    directoryRelativePath: string
  ): Promise<GetFilesResponse> {
    const theBucket = firebaseStorage().bucket(bucketName)
    // 2022-06-10 00:18:50 v low priority issue, but there's a weird type incompatability between firebase-admin consuming @google-cloud storage but the types being slightly out of sync, so force typing this to be the GCS type here
    // the error shows:  Property 'crc32cGenerator' is missing in type 'import("/Users/jared/Documents/GitHub/mirror-server/node_modules/firebase-admin/node_modules/@google-cloud/storage/build/src/file").File' but required in type 'import("/Users/jared/Documents/GitHub/mirror-server/node_modules/@google-cloud/storage/build/src/file").File'.
    return (await theBucket.getFiles({
      prefix: directoryRelativePath
    })) as unknown as GetFilesResponse
  }

  private _getFileTypeEnding(mimeType: string): string {
    if (mimeType in this.mimeTypeFileMap) {
      return this.mimeTypeFileMap[mimeType]
    }

    const supportedMimes = Object.keys(this.mimeTypeFileMap).join(', ')
    const supportedMessage = `Supported MIME types: ${supportedMimes}`
    throw new Error(
      `MIME type ${mimeType} is not supported. ${supportedMessage}`
    )
  }
  // Inverse of _getFileTypeEnding
  private _getMimeTypeFromFileNameEnding(name: string): string {
    const fileEnding = '.' + name.split('.').pop()
    if (
      fileEnding &&
      Object.values(this.mimeTypeFileMap).includes(fileEnding)
    ) {
      return Object.keys(this.mimeTypeFileMap).find(
        (key) => this.mimeTypeFileMap[key] === fileEnding
      )
    }

    const supportedFileEndings = Object.keys(this.mimeTypeFileMap).join(', ')
    const supportedMessage = `Supported file endings: ${supportedFileEndings}`
    throw new Error(
      `File ending ${fileEnding} is not supported. ${supportedMessage}`
    )
  }

  /**
   * START Section: Batch file upload  ------------------------------------------------------
   */
  /**
   * @description This should be run as one-off from HTTP request, ideally from a Retool dashboard or something similar
   * @date 2023-09-02 17:39
   */
  async batchAssetUploadFromQueueBucket(
    useCloudQueueBucket = true,
    inputFolderNameForLocal = 'inputs'
  ) {
    const QUEUE_BUCKET_NAME = 'the-mirror-asset-queue'

    // Find files

    if (useCloudQueueBucket) {
      // ensure that we're using remote mongo
      if (
        !process.env.MONGODB_URL ||
        (process.env.MONGODB_URL as string).includes('local')
      ) {
        throw new Error('Trying to use local mongo for a remote upload')
      }
      // ensure that this is only on dev
      if (!(process.env.MONGODB_URL as string).includes('dev')) {
        throw new Error('This script should only be run on dev')
      }
      const storage = new Storage()
      const bucket = storage.bucket(QUEUE_BUCKET_NAME)
      const [cloudFiles] = await bucket.getFiles()
      const uploadPromises = cloudFiles.map(async (file) => {
        const name = file.name
        // ensure that it's not the directory
        if (!name.includes(QUEUE_BUCKET_NAME)) {
          const [contents]: DownloadResponse = await bucket
            .file(name)
            .download()
          return this.runUploadFileForBatchProcess(name, contents)
        }
      })
      await Promise.all(uploadPromises)
      console.log('Finished batchAssetUploadFromQueueBucket from cloud bucket')
    } else {
      const files = fs.readdirSync(inputFolderNameForLocal)
      const uploadPromises = files.map((fileName) => {
        const inputFolderPath = __dirname + `/${inputFolderNameForLocal}/`
        const name = this.capitalizeFirstLetter(
          fileName.slice(0, fileName.length - 4)
        )
        const fileBuffer = fs.readFileSync(inputFolderPath + fileName)
        return this.runUploadFileForBatchProcess(name, fileBuffer)
      })

      await Promise.all(uploadPromises)
    }
  }

  public async moveAllObjectsFromQueueBucketToQueueCompletedBucket() {
    const sourceBucketName = 'the-mirror-asset-queue'
    const destinationBucketName = 'the-mirror-asset-queue-completed'
    const storage = new Storage()
    const sourceBucket = storage.bucket(sourceBucketName)
    const [files] = await sourceBucket.getFiles({
      delimiter: '/'
    })

    files.forEach(async (file) => {
      await file.move(destinationBucketName + '/' + file.name)
    })
  }

  private async runUploadFileForBatchProcess(name: string, fileBuffer) {
    const asset = await this.assetService.createAsset({
      ownerId: ASSET_MANAGER_UID,
      name,
      assetType: ASSET_TYPE.MESH,
      mirrorPublicLibrary: true
    })
    console.log('Created asset' + name)

    const { publicUrl: currentFile } =
      await this.assetService.uploadAssetFilePublicWithRolesCheck({
        assetId: asset._id,
        userId: ASSET_MANAGER_UID,
        file: {
          buffer: fileBuffer,
          mimetype: this._getMimeTypeFromFileNameEnding(name)
        } as Express.Multer.File
      })

    await this.assetService.updateOneWithRolesCheck(
      ASSET_MANAGER_UID,
      asset._id,
      {
        currentFile
      }
    )
    console.log('Uploaded ' + name + ' ' + asset._id)
  }

  private capitalizeFirstLetter(string) {
    return string.charAt(0).toUpperCase() + string.slice(1)
  }
  /**
   * END Section: Batch file upload  ------------------------------------------------------
   */

  /**
   * START Section: Local driver  ------------------------------------------------------
   */
  async uploadFileLocal(
    file: Express.Multer.File,
    pathWithFileType: string
  ): Promise<string> {
    const directoryPath = this.getLocalStoragePath()
    const filePath = path.join(directoryPath, pathWithFileType)
    console.log('Uploading file to local storage:', this.getLocalStoragePath())
    try {
      await fs.promises.mkdir(path.dirname(filePath), { recursive: true }) // Create directory recursively if it doesn't exist
      await fs.promises.writeFile(filePath, file.buffer)
      console.log('File uploaded to local storage:', filePath)
      return filePath
    } catch (error) {
      console.error('Error uploading file:', error)
      throw error
    }
  }

  async copyFileLocal(fromPath: string, toPath: string): Promise<string> {
    if (!fs.existsSync(fromPath)) {
      throw new Error(`File does not exist at path: ${fromPath}`)
    }
    const directoryPath = this.getLocalStoragePath()
    const toFilePath = path.join(directoryPath, toPath)
    await fs.promises.mkdir(path.dirname(toFilePath), { recursive: true }) // Create directory recursively if it doesn't exist
    await fs.promises.copyFile(fromPath, toFilePath)
    return toFilePath
  }

  getLocalStoragePath(): string {
    const localStorage = 'localStorage' // Define the relative path to the local storage directory
    return path.join(__dirname, '..', '..', '..', localStorage)
  }
  /**
   * END Section: Local driver  ------------------------------------------------------
   */
}

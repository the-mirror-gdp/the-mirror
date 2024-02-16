import { DownloadResponse, Storage } from '@google-cloud/storage'
import { Injectable } from '@nestjs/common'
import { StorageFile } from './storage.file'

@Injectable()
export class StorageService {
  private storage: Storage

  constructor() {
    const projectId = process.env.GCP_PROJECT_ID
    const keyFilename = process.env.GCS_KEYFILE
    this.storage = new Storage({
      projectId,
      keyFilename
    })
  }

  async get(bucket: string, path: string): Promise<StorageFile> {
    const fileResponse: DownloadResponse = await this.storage
      .bucket(bucket)
      .file(path)
      .download()
    const [buffer] = fileResponse
    const storageFile: StorageFile = {
      buffer,
      metadata: new Map<string, string>(),
      contentType: undefined ?? ''
    }
    return storageFile
  }

  async getWithMetaData(bucket: string, path: string): Promise<StorageFile> {
    const [metadata] = await this.storage
      .bucket(bucket)
      .file(path)
      .getMetadata()
    const fileResponse: DownloadResponse = await this.storage
      .bucket(bucket)
      .file(path)
      .download()
    const [buffer] = fileResponse

    const metadataMap = new Map<string, string>(Object.entries(metadata || {}))
    const storageFile: StorageFile = {
      buffer,
      metadata: metadataMap,
      contentType: metadataMap.get('contentType')
    }
    return storageFile
  }
}

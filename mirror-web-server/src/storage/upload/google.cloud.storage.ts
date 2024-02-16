import { Bucket } from '@google-cloud/storage'
import { Request } from 'express'
import { ParamsDictionary } from 'express-serve-static-core'
import multer from 'multer'
import { ParsedQs } from 'qs'
import { v4 as uuidv4 } from 'uuid'

type Options = {
  bucket: Bucket
}

export interface CustomFileResult extends Partial<Express.Multer.File> {
  name: string
}

class GoogleCloudStorageEngine implements multer.StorageEngine {
  private bucket: Bucket

  constructor(options: Options) {
    this.bucket = options.bucket
  }

  _handleFile(
    req: Request<ParamsDictionary, any, any, ParsedQs, Record<string, any>>,
    file: Express.Multer.File,
    callback: (error?: any, info?: CustomFileResult) => void
  ): void {
    const fileName = uuidv4()
    const storageFile = this.bucket.file(fileName)
    const fileWriteStream = storageFile.createWriteStream()

    const fileReadStream = file.stream
    fileReadStream
      .pipe(fileWriteStream)
      .on('error', (error) => {
        console.log('error: ', error)
        fileWriteStream.end()
        storageFile.delete({ ignoreNotFound: true })
        callback(error)
      })
      .on('finish', () => {
        console.log('finished upload')
        callback(null, { name: fileName })
      })
  }

  _removeFile(
    req: Request<ParamsDictionary, any, any, ParsedQs, Record<string, any>>,
    file: Express.Multer.File,
    callback: (error: Error) => void
  ): void {
    this.bucket.file(file.filename).delete({ ignoreNotFound: true }) // Delete file if found in bucket
    callback(null)
  }
}

export default (opts: Options) => {
  return new GoogleCloudStorageEngine(opts)
}

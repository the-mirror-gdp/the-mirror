import { PredefinedAcl } from '@google-cloud/storage'

export interface FileUploadInterface {
  streamFile(
    bucketName: string,
    relativePath: string,
    file: Express.Multer.File,
    acl: PredefinedAcl
  ): Promise<any>

  getFiles(bucketName: string, directoryRelativePath: string): Promise<any>
}

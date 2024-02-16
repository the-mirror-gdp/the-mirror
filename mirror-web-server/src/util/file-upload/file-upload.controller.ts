/*
https://docs.nestjs.com/controllers#controllers
*/

import { Controller, Post, UseGuards } from '@nestjs/common'
import { FileUploadService } from './file-upload.service'
import { AdminUtilGuard } from '../../godot-server/admin-util.guard'
import { SetRequestTimeout } from '../timeout-interceptor'

@Controller('file-upload')
@UseGuards(AdminUtilGuard)
export class FileUploadController {
  constructor(private fileUploadService: FileUploadService) {}

  @Post('batch-upload-assets-from-bucket')
  @SetRequestTimeout(15 * 1000 * 60)
  async batchAssetUploadFromQueueBucket() {
    await this.fileUploadService.batchAssetUploadFromQueueBucket()
    await this.fileUploadService.moveAllObjectsFromQueueBucketToQueueCompletedBucket()
  }
}

import { Module, forwardRef } from '@nestjs/common'
import { FileUploadService } from './file-upload.service'
import { FileUploadController } from './file-upload.controller'
import { AssetModule } from '../../asset/asset.module'
import { LoggerModule } from '../logger/logger.module'

@Module({
  imports: [
    LoggerModule,
    forwardRef(() => AssetModule) // to fix circular dependency
  ],
  controllers: [FileUploadController],
  providers: [FileUploadService],
  exports: [FileUploadService]
})
export class FileUploadModule {}

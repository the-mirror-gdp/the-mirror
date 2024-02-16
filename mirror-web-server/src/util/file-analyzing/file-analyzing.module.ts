import { Global, Module } from '@nestjs/common'
import { AssetAnalyzingService } from './asset-analyzing.service'
import { LoggerModule } from '../logger/logger.module'
import { NodeIO } from '@gltf-transform/core'

@Global()
@Module({
  providers: [
    AssetAnalyzingService,
    { provide: 'NODE_IO', useFactory: () => new NodeIO() }
  ],
  exports: [AssetAnalyzingService],
  imports: [LoggerModule]
})
export class FileAnalyzingModule {}

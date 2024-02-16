import { Module } from '@nestjs/common'
import { RoleModule } from '../../roles/role.module'
import { LoggerModule } from '../logger/logger.module'
import { PaginationService } from './pagination.service'

@Module({
  imports: [LoggerModule, RoleModule],
  providers: [PaginationService],
  exports: [PaginationService]
})
export class PaginationModule {}

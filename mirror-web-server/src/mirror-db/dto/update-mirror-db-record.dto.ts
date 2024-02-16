import { ApiProperty } from '@nestjs/swagger'
import { IsNotEmpty, IsObject } from 'class-validator'

export class UpdateMirrorDBRecordDto {
  @IsNotEmpty()
  @IsObject()
  @ApiProperty()
  recordData: Record<string, unknown>
}

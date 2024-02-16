import { ApiProperty } from '@nestjs/swagger'
import { IsBoolean, IsString } from 'class-validator'

export class FileUploadPublicApiResponse {
  @IsBoolean()
  @ApiProperty()
  success: boolean

  @IsString()
  @ApiProperty()
  publicUrl: string
}

export class FileUploadApiResponse {
  @IsBoolean()
  @ApiProperty()
  success: boolean

  @IsString()
  @ApiProperty()
  relativePath: string
}

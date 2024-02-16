import { IsNotEmpty, IsString } from 'class-validator'
export class UploadAssetFileDto {
  @IsNotEmpty()
  @IsString()
  userId: string

  @IsNotEmpty()
  @IsString()
  assetId: string

  @IsNotEmpty()
  file: Express.Multer.File
}

import { IsArray, IsNotEmpty, IsString } from 'class-validator'

export class UploadSpaceFilesDto {
  @IsNotEmpty()
  @IsString()
  spaceId: string

  @IsNotEmpty()
  @IsArray()
  files: Express.Multer.File[]
}

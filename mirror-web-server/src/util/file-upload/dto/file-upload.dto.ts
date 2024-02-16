import { IsNotEmpty, IsString } from 'class-validator'

export class FileUploadDto {
  @IsNotEmpty()
  @IsString()
  path: string

  @IsNotEmpty()
  file: Express.Multer.File
}

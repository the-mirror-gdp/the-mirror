import { IsNotEmpty, IsString } from 'class-validator'

export class UploadProfileFileDto {
  @IsNotEmpty()
  @IsString()
  userId: string

  @IsNotEmpty()
  file: Express.Multer.File
}

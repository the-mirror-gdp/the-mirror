import { ArrayMaxSize, IsArray, IsNotEmpty, IsString } from 'class-validator'

export class UpdateUserSidebarTagsDto {
  @IsNotEmpty()
  @IsArray()
  @ArrayMaxSize(3)
  @IsString({ each: true })
  sidebarTags: string[]
}

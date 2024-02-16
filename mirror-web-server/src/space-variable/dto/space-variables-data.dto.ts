import { IsNotEmpty, IsString } from 'class-validator'

export class CreateSpaceVariablesDataDocumentDto {
  /**
   * @description We intentionally use a "data" property here so that other keys can be added in the future and the dto doesn't assume that everything in the dto should be saved to the database
   * We also want to be able to store top-level key:value pairs that the user doesn't have free reign access to.
   * @date 2023-03-03 00:12
   */
  @IsNotEmpty()
  data: any
}

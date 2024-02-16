import { ApiProperty } from '@nestjs/swagger'
import { IsOptional, IsString } from 'class-validator'

export class CreatePlayServerDto {
  @IsOptional()
  @IsString()
  @ApiProperty({ required: false })
  zoneName?: string
}

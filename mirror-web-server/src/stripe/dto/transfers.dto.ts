import { ApiProperty } from '@nestjs/swagger'
import { IsNotEmpty, IsNumber, IsString } from 'class-validator'
export class TransfersDto {
  @IsNotEmpty()
  @IsNumber()
  @ApiProperty()
  amount: number

  @IsNotEmpty()
  @IsString()
  @ApiProperty()
  currency: string

  @IsNotEmpty()
  @IsString()
  @ApiProperty()
  destination: string
}

import { ApiProperty } from '@nestjs/swagger'
import { IsNotEmpty, IsString } from 'class-validator'
export class AddBank {
  @IsNotEmpty()
  @IsString()
  @ApiProperty()
  token: string
}

export class AddCard {
  @IsNotEmpty()
  @IsString()
  @ApiProperty()
  token: string
}

export class CardToken {
  @IsNotEmpty()
  @IsString()
  @ApiProperty()
  number: string

  @IsNotEmpty()
  @IsString()
  @ApiProperty()
  exp_month: string

  @IsNotEmpty()
  @IsString()
  @ApiProperty()
  exp_year: string

  @IsNotEmpty()
  @IsString()
  @ApiProperty()
  cvc: string
}

import { ApiProperty } from '@nestjs/swagger'
import { IsNotEmpty, IsNumber, IsString, IsOptional } from 'class-validator'
export class SubscriptionDto {
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
  productId: string

  // Important: If the product and price were manually created using the Stripe dashboard,
  // you'll need the specific 'priceId' to properly create new subscriptions.
  // Example: When a user purchases assets, we dynamically create the Stripe product and price during the asset creation process. However, for platform subscriptions, since there's no specific endpoint available, we manually create the product and prices directly from the Stripe dashboard.

  @IsOptional()
  @IsString()
  @ApiProperty({
    description:
      "If the product and price were manually created using the Stripe CLI,you'll need the specific 'priceId' to properly create new subscriptions."
  })
  priceId: string

  @IsOptional()
  @IsString()
  @ApiProperty()
  destination: string
}

export class ProductDto {
  @IsNotEmpty()
  @IsString()
  @ApiProperty()
  name: string

  @IsNotEmpty()
  @IsString()
  @ApiProperty()
  description: string
}

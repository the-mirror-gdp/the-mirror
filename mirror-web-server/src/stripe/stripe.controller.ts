import {
  Controller,
  Get,
  Post,
  Body,
  Param,
  Delete,
  UsePipes,
  ValidationPipe,
  RawBodyRequest,
  Req,
  BadRequestException,
  Patch
} from '@nestjs/common'
import { StripeService } from './stripe.service'
import { Stripe } from 'stripe'
import { FirebaseTokenAuthGuard } from '../auth/auth.guard'
import { ApiParam } from '@nestjs/swagger'
import { AddBank, AddCard, CardToken } from './dto/token.dto'
import { UserToken } from '../auth/get-user.decorator'
import { UserId } from '../util/mongo-object-id-helpers'
import { PaymentIntentDto } from './dto/paymentIntent.dto'
import { TransfersDto } from './dto/transfers.dto'
import { ProductDto, SubscriptionDto } from './dto/subscription.dto'
import { PublicFirebaseAuthNotRequired } from '../auth/public.decorator'
@Controller('stripe')
@FirebaseTokenAuthGuard()
@UsePipes(new ValidationPipe({ whitelist: true }))
export class StripeController {
  constructor(private readonly stripeService: StripeService) {}

  /**
   * 2023-07-24 11:12:23 Note: I'm commenting these out because it was old code and I don't think we need to expose all these. The implementation also wasn't secure with allowing an userId to be specified.
   */
  @Post('/setup-intent')
  @FirebaseTokenAuthGuard()
  public async setupIntent(
    @UserToken('user_id') userId: UserId,
    @Body() data: { payment_method: string }
  ) {
    return await this.stripeService.setupIntent(userId, data)
  }

  @Post('/customer')
  @FirebaseTokenAuthGuard()
  public async createCustomerAccount(@UserToken('user_id') userId: UserId) {
    return await this.stripeService.createCustomerAccount(userId)
  }

  @Post('/connect')
  @FirebaseTokenAuthGuard()
  public async createConnectAccount(@UserToken('user_id') userId: UserId) {
    return await this.stripeService.createConnectAccount(userId)
  }

  @Delete('/connect')
  @FirebaseTokenAuthGuard()
  public async deleteConnectAccount(@UserToken('user_id') userId: UserId) {
    return await this.stripeService.deleteConnectAccount(userId)
  }

  @Post('/card')
  @FirebaseTokenAuthGuard()
  public async createCard(
    @Body() { token }: AddCard,
    @UserToken('user_id') userId: UserId
  ): Promise<Stripe.CustomerSource[]> {
    return await this.stripeService.createCard(userId, token)
  }

  @Get('/cards')
  @FirebaseTokenAuthGuard()
  public async getCardsList(@UserToken('user_id') userId: UserId) {
    return await this.stripeService.getCardsList(userId)
  }

  @Get('/account-info')
  @FirebaseTokenAuthGuard()
  public async getStripeAccountInfo(@UserToken('user_id') userId: UserId) {
    return await this.stripeService.getStripeAccountInfo(userId)
  }

  @Post('/bank-account')
  @FirebaseTokenAuthGuard()
  public async addBankAccount(
    @Body() tokenData: AddBank,
    @UserToken('user_id') userId: UserId
  ) {
    return await this.stripeService.addBankToken(userId, tokenData)
  }

  @Delete('/card/:idCard')
  @FirebaseTokenAuthGuard()
  @ApiParam({ name: 'idCard', type: 'string', required: true })
  public async deleteCard(
    @UserToken('user_id') userId: UserId,
    @Param('idCard') cardId: string
  ) {
    return await this.stripeService.deleteCard(userId, cardId)
  }

  @Post('/card/:paymentMethodId')
  @FirebaseTokenAuthGuard()
  @ApiParam({ name: 'paymentMethodId', type: 'string', required: true })
  public async setDefaultPaymentMethod(
    @UserToken('user_id') userId: UserId,
    @Param('paymentMethodId') paymentMethodId: string
  ) {
    return await this.stripeService.setDefaultPaymentMethod(
      userId,
      paymentMethodId
    )
  }

  @Post('/payment-intent')
  @FirebaseTokenAuthGuard()
  public async createPaymentIntent(
    @UserToken('user_id') userId: UserId,
    @Body() data: PaymentIntentDto
  ) {
    return await this.stripeService.createPaymentIntent(userId, data)
  }

  @Get('/payment-methods')
  @FirebaseTokenAuthGuard()
  public async getPaymentMethods(@UserToken('user_id') userId: UserId) {
    return await this.stripeService.getPaymentMethods(userId)
  }

  @Post('/transfers')
  @FirebaseTokenAuthGuard()
  @ApiParam({ name: 'destinationUserId', type: 'string', required: true })
  public async transfersAmount(@Body() data: TransfersDto) {
    return await this.stripeService.transfersAmount(data)
  }

  // Create product for Subscription

  @Post('/product')
  @FirebaseTokenAuthGuard()
  public async createProduct(
    @UserToken('user_id') userId: UserId,
    @Body() data: ProductDto
  ) {
    return await this.stripeService.createProduct(userId, data)
  }

  // Get all products.

  @Get('/products')
  @FirebaseTokenAuthGuard()
  public async getAllProductsWithPrice(@UserToken('user_id') userId: UserId) {
    return await this.stripeService.getAllProductsWithPrice(userId)
  }

  //Creating Subscription.

  @Post('/subscription')
  @FirebaseTokenAuthGuard()
  public async createSubscription(
    @UserToken('user_id') userId: UserId,
    @Body() data: SubscriptionDto
  ) {
    return await this.stripeService.createSubscription(userId, data)
  }

  @Patch('/subscription/pause')
  @FirebaseTokenAuthGuard()
  public async pauseSubscription(@UserToken('user_id') userId: UserId) {
    return await this.stripeService.pauseSubscription(userId)
  }

  @Patch('/subscription/resume')
  @FirebaseTokenAuthGuard()
  public async resumeSubscription(@UserToken('user_id') userId: UserId) {
    return await this.stripeService.resumeSubscription(userId)
  }

  @Delete('/subscription')
  @FirebaseTokenAuthGuard()
  public async deleteSubscription(@UserToken('user_id') userId: UserId) {
    return await this.stripeService.deleteSubscription(userId)
  }

  @Get('/dashboard-link')
  @FirebaseTokenAuthGuard()
  public async createDashboardLink(@UserToken('user_id') userId: UserId) {
    return await this.stripeService.createDashboardLink(userId)
  }

  @Get('/customer-portal-link')
  @FirebaseTokenAuthGuard()
  public async createCustomerPortalLink(@UserToken('user_id') userId: UserId) {
    return await this.stripeService.createCustomerPortalLink(userId)
  }

  @Post('/webhook')
  @PublicFirebaseAuthNotRequired()
  public async handleStripeWebhook(
    @Req() req: RawBodyRequest<Request>
  ): Promise<any> {
    if (!req.rawBody) {
      throw new BadRequestException('Invalid payload')
    }
    const raw = req.rawBody.toString('utf8')
    const json = JSON.parse(raw)
    return await this.stripeService.handleStripeWebhook(json)
  }
}

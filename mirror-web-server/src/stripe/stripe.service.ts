import { Injectable, Inject, BadRequestException } from '@nestjs/common'
import { InjectModel } from '@nestjs/mongoose'
import { Model } from 'mongoose'
import {
  PaymentMethodsTypes,
  StripeAccountLinkType,
  StripeAccountType,
  STRIPE_CLIENT
} from './constants'
import { User, UserDocument } from '../user/user.schema'
import { Stripe } from 'stripe'
import { FirebaseTokenAuthGuard } from '../auth/auth.guard'
import { AddBank, CardToken } from './dto/token.dto'
import { PaymentIntentDto } from './dto/paymentIntent.dto'
import { TransfersDto } from './dto/transfers.dto'
import { ProductDto, SubscriptionDto } from './dto/subscription.dto'
import { StripeSubscriptionMetadataDto } from './dto/metadata.dto'
import { STRIPE_WEBHOOK_TYPES } from './webhooks.types'
import { PREMIUM_ACCESS } from '../option-sets/premium-tiers'

@Injectable()
@FirebaseTokenAuthGuard()
export class StripeService {
  constructor(
    @InjectModel(User.name) private userModel: Model<UserDocument>,
    @Inject(STRIPE_CLIENT) private readonly stripe: Stripe
  ) {}

  public async setupIntent(userId: string, data) {
    const user = await this.userModel.findById(userId).exec()
    // Create Payment Intent
    const setupIntent = await this.stripe.setupIntents.create({
      customer: user.stripeCustomerId,
      payment_method: data.payment_method,
      payment_method_types: [
        PaymentMethodsTypes.BANCONTACT,
        PaymentMethodsTypes.CARD,
        PaymentMethodsTypes.IDEAL
      ]
    })
    return { client_secret: setupIntent.client_secret }
  }

  public async createCustomerAccount(userId: string) {
    //Create Account
    const user = await this.userModel.findById(userId).exec()
    if (!user.stripeCustomerId) {
      const customer = await this.stripe.customers.create({
        name: user.displayName,
        email: user.email
      })

      //add to the user their account id
      return await this.userModel
        .findByIdAndUpdate(
          userId,
          { stripeCustomerId: customer.id },
          { new: true }
        )
        .exec()
    }
  }

  public async createConnectAccount(userId: string) {
    //Create Account
    const user = await this.userModel.findById(userId).exec()
    if (!user.stripeAccountId) {
      const account = await this.stripe.accounts.create({
        type: StripeAccountType.EXPRESS,
        email: user.email
      })

      // add to the user their account id
      await this.userModel
        .findByIdAndUpdate(
          userId,
          { stripeAccountId: account.id },
          { new: true }
        )
        .exec()
      //Create accountLink
      return await this.stripe.accountLinks.create({
        account: account.id,
        refresh_url: process.env.STRIPE_RETURN_URL,
        return_url: process.env.STRIPE_RETURN_URL,
        type: StripeAccountLinkType.ONBOARDING
      })
    }

    return await this.stripe.accountLinks.create({
      account: user.stripeAccountId,
      refresh_url: process.env.STRIPE_RETURN_URL,
      return_url: process.env.STRIPE_RETURN_URL,
      type: StripeAccountLinkType.ONBOARDING
    })
  }

  public async deleteConnectAccount(userId: string) {
    const user = await this.userModel.findById(userId)

    await this.stripe.accounts.del(user.stripeAccountId)
    // Revoke premium access if a user's Stripe Connect account is deleted

    return await this.userModel.findByIdAndUpdate(
      user.id,
      {
        $pull: { premiumAccess: PREMIUM_ACCESS.PREMIUM_1 },
        $unset: {
          stripeAccountId: 1,
          stripeCustomerId: 1
        }
      },
      { new: true }
    )
  }

  public async addBankToken(userId, data: AddBank) {
    const user = await this.userModel.findById(userId).exec()

    // Add external bank account to user's stripe account

    return await this.stripe.accounts.createExternalAccount(
      user.stripeAccountId,
      {
        external_account: data.token
      }
    )
  }

  public async getCardToken(tokenData: CardToken) {
    // Get card token
    return await this.stripe.tokens.create({
      card: {
        number: tokenData.number,
        exp_month: tokenData.exp_month,
        exp_year: tokenData.exp_year,
        cvc: tokenData.cvc
      }
    })
  }

  public async createCard(userId: string, token: string) {
    const user = await this.userModel.findById(userId).exec()
    // Create card and attached to user's connect stripe account
    await this.stripe.customers.createSource(user.stripeCustomerId, {
      source: token
    })
    const cardsList = await this.stripe.customers.listSources(
      user.stripeCustomerId,
      {
        object: 'card'
      }
    )
    return cardsList.data
  }

  public async getCardsList(userId: string) {
    const user = await this.userModel.findById(userId).exec()
    //If the customer dont have id create a new Customer for stripe
    if (!user.stripeCustomerId) {
      throw new BadRequestException(`User is not a Stripe Customer`)
    }

    return this.getCardList(user.stripeCustomerId)
  }
  public async getStripeAccountInfo(userId: string) {
    const user = await this.userModel.findById(userId).exec()
    const account = await this.stripe.accounts.retrieve(user.stripeAccountId)
    return account
  }

  public async deleteCard(userId: string, cardId: string) {
    const user = await this.userModel.findById(userId).exec()
    // Delete card from user's stripe account
    await this.stripe.customers.deleteSource(user.stripeCustomerId, cardId)
    const cardsList = await this.stripe.customers.listSources(
      user.stripeCustomerId,
      {
        object: 'card'
      }
    )
    return cardsList.data
  }

  public async setDefaultPaymentMethod(
    userId: string,
    paymentMethodId: string
  ) {
    const user = await this.userModel.findById(userId).exec()
    // Delete card from user's stripe account
    await this.stripe.customers.update(user.stripeCustomerId, {
      invoice_settings: { default_payment_method: paymentMethodId },
      default_source: paymentMethodId
    })
    return this.getCardList(user.stripeCustomerId)
  }

  public async createPaymentIntent(userId: string, data: PaymentIntentDto) {
    const user = await this.userModel.findById(userId).exec()
    // Create Payment Intent
    const paymentIntent = await this.stripe.paymentIntents.create({
      amount: data.amount,
      currency: data.currency,
      customer: user.stripeCustomerId,
      payment_method: data.payment_method,
      payment_method_types: [
        PaymentMethodsTypes.BANCONTACT,
        PaymentMethodsTypes.CARD,
        PaymentMethodsTypes.IDEAL
      ]
    })
    return { client_secret: paymentIntent.client_secret }
  }

  public async getPaymentMethods(userId: string) {
    const user = await this.userModel.findById(userId).exec()
    // Create Payment Intent
    return await this.getPaymentMethodsList(user.stripeCustomerId)
  }

  public async transfersAmount(data: TransfersDto) {
    // Finding details for destination user
    const destinationUser = await this.userModel
      .findById(data.destination)
      .exec()

    return await this.stripe.transfers.create({
      amount: data.amount,
      currency: data.currency,
      destination: destinationUser.stripeAccountId
    })
  }

  public async createSubscription(userId: string, data: SubscriptionDto) {
    const { destination } = data
    const user = await this.userModel.findById(userId).exec()

    const destinationAccount = await this.userModel.findById(destination).exec()

    const subscription = await this.createStripeSubscription(
      user.stripeCustomerId,
      destinationAccount?.stripeAccountId || null,
      data,
      { userId }
    )
    const object: any = subscription.latest_invoice
    return {
      client_secret: object?.payment_intent?.client_secret
    }
  }

  public async deleteSubscription(userId: string) {
    const user = await this.userModel.findById(userId).exec()

    if (!user.premiumAccess.includes(PREMIUM_ACCESS.PREMIUM_1)) {
      throw new BadRequestException(`Subscription not found`)
    }

    return await this.stripe.subscriptions.cancel(user.stripeSubscriptionId)
  }

  /**
   * Pauses the subscription for the given user.
   *
   * @param userId - The ID of the user whose subscription needs to be paused.
   * @see {@link https://stripe.com/docs/billing/subscriptions/pause |Stripe API Documentation - Pause a subscription}
   */

  public async pauseSubscription(userId: string) {
    const user = await this.userModel.findById(userId).exec()

    if (!user.premiumAccess.includes(PREMIUM_ACCESS.PREMIUM_1)) {
      throw new BadRequestException(`Subscription not found`)
    }

    return await this.stripe.subscriptions.update(user.stripeSubscriptionId, {
      pause_collection: { behavior: 'void' } // Pauses the subscription without any specific behavior.
    })
  }

  public async resumeSubscription(userId: string) {
    const user = await this.userModel.findById(userId).exec()

    if (user.premiumAccess.includes(PREMIUM_ACCESS.PREMIUM_1)) {
      throw new BadRequestException(`You already have an active subscription.`)
    }

    return await this.stripe.subscriptions.update(user.stripeSubscriptionId, {
      pause_collection: null
    })
  }

  public async createProduct(userId: string, productData: ProductDto) {
    // Finding details for destination user
    const user = await this.userModel.findById(userId).exec()

    return await this.stripe.products.create({
      name: productData.name,
      description: productData.description
    })
  }

  public async getAllProductsWithPrice(userId: string) {
    // Finding details for destination user
    const prices = await this.stripe.prices.list()

    await Promise.all(
      prices.data.map(async (price) => {
        price['productData'] = await this.stripe.products.retrieve(
          price.product as string,
          { stripeAccount: '' }
        )
      })
    )

    return prices
  }

  private async createStripeSubscription(
    stripeCustomer: string,
    destinationAccount: string,
    data: SubscriptionDto,
    metadata: StripeSubscriptionMetadataDto
  ) {
    // Important: If the product and price were manually created using the Stripe CLI,
    // you'll need the specific 'priceId' to properly create new subscriptions.

    return data.priceId
      ? await this.stripe.subscriptions.create({
          customer: stripeCustomer,
          items: [
            {
              price: data.priceId
            }
          ],
          currency: data.currency,
          payment_settings: {
            payment_method_types: ['card'],
            save_default_payment_method: 'on_subscription'
          },
          ...(destinationAccount //transfer_data when destinationAccount available
            ? {
                transfer_data: {
                  destination: destinationAccount
                }
              }
            : {}),
          metadata: { ...metadata },
          expand: ['latest_invoice.payment_intent']
        })
      : await this.stripe.subscriptions.create({
          customer: stripeCustomer,
          items: [
            {
              price_data: {
                currency: data.currency,
                unit_amount: data.amount,
                recurring: {
                  interval: 'month'
                },
                product: data.productId
              }
            }
          ],
          currency: data.currency,
          payment_settings: {
            payment_method_types: ['card'],
            save_default_payment_method: 'on_subscription'
          },
          ...(destinationAccount //transfer_data when destinationAccount available
            ? {
                transfer_data: {
                  destination: destinationAccount
                }
              }
            : {}),
          metadata: { ...metadata },
          expand: ['latest_invoice.payment_intent']
        })
  }

  private async getCardList(stripeId: string) {
    // Card List
    const cardsList: any = await this.stripe.customers.listSources(stripeId, {
      object: 'card'
    })
    // Logic for default card method.
    const customer: any = await this.stripe.customers.retrieve(stripeId)
    const result = cardsList.data.map((e) => {
      e.id === customer.default_source
        ? (e.default = true)
        : (e.default = false)
      return e
    })
    return result
  }

  private async getPaymentMethodsList(stripeId: string) {
    // Payment Methods List
    const paymentMethods = await this.stripe.customers.listPaymentMethods(
      stripeId
    )
    const paymentMethodsList: any = paymentMethods.data.map((e) => {
      return { ...e.card, id: e.id }
    })
    // Retrive customer default payment method.
    const customer: any = await this.stripe.customers.retrieve(stripeId, {
      expand: ['invoice_settings.default_payment_method']
    })
    // Update default payment methods.
    const result = paymentMethodsList.map((e) => {
      e.id === customer?.invoice_settings?.default_payment_method?.id
        ? (e.default = true)
        : (e.default = false)
      return e
    })

    return result
  }

  public async createDashboardLink(userId: string) {
    const user = await this.userModel.findById(userId).exec()

    return await this.stripe.accounts.createLoginLink(user.stripeAccountId)
  }

  /**
   *The Customer Portal Features section provides a comprehensive overview of the powerful tools and functionalities offered by Stripe's Customer Portal.
   *It's impressive to see how seamlessly users can manage their billing preferences, update payment methods,handle subscription and access their payment history.
   * @param userId - The ID of the user whose subscription needs to be paused.
   * @see {@link https://stripe.com/docs/customer-management#customer-portal-features |Stripe API Documentation - Customer Portal}
   */

  public async createCustomerPortalLink(userId: string) {
    const user = await this.userModel.findById(userId).exec()
    const configurationId = await this.getCustomerPortalConfigurationId()
    return await this.stripe.billingPortal.sessions.create({
      customer: user.stripeCustomerId,
      configuration: configurationId,
      return_url: process.env.STRIPE_RETURN_URL
    })
  }

  private async getCustomerPortalConfigurationId() {
    // Fetch the list of configurations from the Stripe Billing Portal
    const configuration = await this.stripe.billingPortal.configurations.list({
      active: true
    })

    // Check if there are no existing configurations
    if (configuration.data.length === 0) {
      // If no configuration exists, create a new one with specified features and business profile
      const createdConfiguration =
        await this.stripe.billingPortal.configurations.create({
          features: {
            customer_update: {
              enabled: true,
              allowed_updates: ['email', 'name', 'phone']
            },
            payment_method_update: {
              enabled: true
            },
            invoice_history: {
              enabled: true
            },
            subscription_cancel: {
              enabled: true
            },
            subscription_pause: {
              enabled: true
            }
          },
          business_profile: {
            privacy_policy_url: `https://themirror.space/privacy`,
            terms_of_service_url: `https://themirror.space/terms`
          }
        })

      // Return the ID of the newly created configuration
      return createdConfiguration.id
    }

    // If configurations already exist, return the ID of the first configuration in the list
    return configuration.data[0].id
  }

  public async handleStripeWebhook(rowBody: any) {
    const metaData: StripeSubscriptionMetadataDto = rowBody.data.object.metadata
    switch (rowBody.type) {
      case STRIPE_WEBHOOK_TYPES.SUBSCRIPTION_CREATED:
        await this.userModel.findByIdAndUpdate(metaData.userId, {
          $addToSet: {
            premiumAccess: PREMIUM_ACCESS.PREMIUM_1
          },
          stripeSubscriptionId: rowBody.data.object.id
        })
        break
      case STRIPE_WEBHOOK_TYPES.SUBSCRIPTION_DELETED:
        await this.userModel.findByIdAndUpdate(metaData.userId, {
          $pull: {
            premiumAccess: PREMIUM_ACCESS.PREMIUM_1
          },
          stripeSubscriptionId: null
        })
        break
      case STRIPE_WEBHOOK_TYPES.SUBSCRIPTION_PAUSED:
        await this.userModel.findByIdAndUpdate(metaData.userId, {
          $pull: { premiumAccess: PREMIUM_ACCESS.PREMIUM_1 }
        })
        break
      case STRIPE_WEBHOOK_TYPES.SUBSCRIPTION_RESUMED:
        await this.userModel.findByIdAndUpdate(metaData.userId, {
          $addToSet: { premiumAccess: PREMIUM_ACCESS.PREMIUM_1 }
        })
        break
      // Handle the case when a subscription is updated in a Stripe webhook event
      case STRIPE_WEBHOOK_TYPES.SUBSCRIPTION_UPDATED:
        // Check if the subscription is being canceled via the customer portal
        if (rowBody.data.object.cancel_at) {
          // If cancellation was requested from the customer portal, remove premium access from the user
          await this.userModel.findByIdAndUpdate(metaData.userId, {
            $pull: { premiumAccess: PREMIUM_ACCESS.PREMIUM_1 }
          })
        }
        // Check if the subscription is being renewed from the customer portal
        else if (
          rowBody.data.object.cancel_at === null &&
          !rowBody.data.object.pause_collection
        ) {
          // If the subscription is renewed, add premium access to the user
          await this.userModel.findByIdAndUpdate(metaData.userId, {
            $addToSet: { premiumAccess: PREMIUM_ACCESS.PREMIUM_1 }
          })
        }
        // Check if the subscription is being paused with 'void' behavior
        else if (
          rowBody.data.object.pause_collection &&
          rowBody.data.object.pause_collection.behavior === 'void'
        ) {
          // If paused with 'void' behavior, remove premium access from the user
          await this.userModel.findByIdAndUpdate(metaData.userId, {
            $pull: { premiumAccess: PREMIUM_ACCESS.PREMIUM_1 }
          })
        }
        // Check if the subscription is being resumed
        else if (!rowBody.data.object.pause_collection) {
          // If resumed, add premium access to the user
          await this.userModel.findByIdAndUpdate(metaData.userId, {
            $addToSet: { premiumAccess: PREMIUM_ACCESS.PREMIUM_1 }
          })
        }
        break
    }
  }
}

import { LoggerModule } from './../util/logger/logger.module'
import { DynamicModule, Module, Provider } from '@nestjs/common'
import { Stripe } from 'stripe'
import { STRIPE_CLIENT } from './constants'
import { StripeController } from './stripe.controller'
import { StripeService } from './stripe.service'
import { User, UserSchema } from '../user/user.schema'
import { MongooseModule } from '@nestjs/mongoose'
@Module({})
export class StripeModule {
  static forRoot(apiKey: string, config: Stripe.StripeConfig): DynamicModule {
    const stripe = new Stripe(apiKey, config)

    const stripeProvider: Provider = {
      provide: STRIPE_CLIENT,
      useValue: stripe
    }

    return {
      module: StripeModule,
      providers: [stripeProvider, User, StripeService],
      controllers: [StripeController],
      imports: [
        LoggerModule,
        MongooseModule.forFeature([{ name: User.name, schema: UserSchema }])
      ],
      exports: [stripeProvider],
      global: true
    }
  }
}

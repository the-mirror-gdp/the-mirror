export const STRIPE_CLIENT = 'STRIPE_CLIENT'

export enum PaymentMethodsTypes {
  BANCONTACT = 'bancontact',
  CARD = 'card',
  IDEAL = 'ideal'
}

export enum StripeAccountType {
  STANDARD = 'standard',
  EXPRESS = 'express',
  CUSTOM = 'custom'
}

export enum StripeAccountLinkType {
  ONBOARDING = 'account_onboarding',
  UPDATE = 'account_update'
}

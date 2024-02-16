export enum STRIPE_WEBHOOK_TYPES {
  SUBSCRIPTION_CREATED = 'customer.subscription.created',
  SUBSCRIPTION_DELETED = 'customer.subscription.deleted',
  SUBSCRIPTION_PAUSED = 'customer.subscription.paused',
  SUBSCRIPTION_RESUMED = 'customer.subscription.resumed',
  SUBSCRIPTION_UPDATED = 'customer.subscription.updated',
  DELETE_CONNECT = 'account.application.deauthorized'
}

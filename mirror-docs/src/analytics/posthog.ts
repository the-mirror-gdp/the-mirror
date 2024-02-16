import posthog from 'posthog-js';
import { ANALYTICS_EVENT } from './event.enum';

const postHogApiKey = 'phc_wO5tr7Hle88gRKsDoQIybFqekqTctZ8nXmbokNsCv9b';

export let postHogHasBeenInitialized = false;
export const initPostHog = () => {
  if (typeof window !== 'undefined' && !postHogHasBeenInitialized) {
    posthog.init(postHogApiKey, {
      api_host: 'https://app.posthog.com',
    });
    postHogHasBeenInitialized = true;
  }

  return posthog;
};

export function captureEvent(event: ANALYTICS_EVENT, properties?: any) {
  posthog.capture(event, properties);
}

/**
 * @description Used to ID a user to PostHog with an email
 * @date 2022-08-09 17:37
 */
export function identifyUserUidEmailPostHog(uid: string, email: string) {
  posthog.identify(uid, { email, identifySource: 'mirror-docs' });
}

/**
 * @description Used to ID the user to PostHog without an email
 * @date 2022-08-09 17:37
 */
export function identifyUserUidOnlyPostHog(uid: string) {
  posthog.identify(uid, { identifySource: 'mirror-docs' });
}

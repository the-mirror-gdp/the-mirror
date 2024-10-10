"use client"
import packageJson from '../../package.json';
import { GameAnalytics } from 'gameanalytics'
import { appNameKebabCase } from '@/lib/theme-service';
import { ampli } from '@/src/ampli';
import { sessionReplayPlugin } from '@amplitude/plugin-session-replay-browser';

let analyticsInitialized = false


export function sendAnalyticsEvent(event: any) {
  // don't track if we're not client-side since NextJS renders the HTML on server
  if (typeof window !== 'undefined' && analyticsInitialized) {
    const app = appNameKebabCase();

    // Join the non-empty parts of the event tuple with a colon separator
    const eventDetails = event.filter(Boolean).join(':');

    // Send the event to GameAnalytics with the appended event details
    const eventName = `${app}:${eventDetails}`
    console.log('Analytics: Event: ' + eventName)
    GameAnalytics.addDesignEvent(eventName);

    ampli.track({
      event_type: event,
      app_version: packageJson.version
    })

  }
}


export function setAnalyticsUserId(userId: string) {
  s
  if (typeof window !== 'undefined' && !analyticsInitialized) {
    ampli.client.setUserId(userId)
  }
}


const analytics = function () {
  // Will liklely remote gameanalytics but trying it for a bit
  if (typeof window !== 'undefined' && !analyticsInitialized) {
    if (!process.env.NEXT_PUBLIC_AMPLITUDE_PUBLIC_KEY) {
      throw new Error("Missing analytics key")
    }
    ampli.load({ client: { apiKey: process.env.NEXT_PUBLIC_AMPLITUDE_PUBLIC_KEY } })
    ampli.client.add(sessionReplayPlugin())
    // console.log('Analytics: Initing & starting session')
    console.log('Analytics: Initing')
    // GameAnalytics("configureBuild", `web ${packageJson.version}`);
    GameAnalytics.configureBuild(`web ${packageJson.version}`)
    // set custom dimension 1, whether The Mirror or Reflekt
    // GameAnalytics("setCustomDimension01", appNameKebabCase);
    GameAnalytics.configureAvailableCustomDimensions01(appNameKebabCase);
    // GameAnalytics("initialize", process.env.NEXT_PUBLIC_GA_KEY_GAME_PUBLIC, process.env.NEXT_PUBLIC_GA_KEY_SECRET);
    // GameAnalytics.initialize(process.env.NEXT_PUBLIC_GA_KEY_GAME_PUBLIC, process.env.NEXT_PUBLIC_GA_KEY_SECRET);
    GameAnalytics.initialize('16f053bf9aa8bdb4339f013d3af5bf58', '27ba60bcc570fb3d5eb63ec081ddf09647ccb456');
    GameAnalytics.startSession()
    analyticsInitialized = true
  }

}

analytics()

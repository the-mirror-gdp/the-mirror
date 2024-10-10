"use client"
import { useEffect } from 'react';
import packageJson from '../../package.json';
import { GameAnalytics } from 'gameanalytics'
import { AppNameKebabCaseType, appNameKebabCase } from '@/lib/theme-service';
import * as amplitude from '@amplitude/analytics-browser';

let analyticsInitialized = false

type GameAnalyticsEvent = [string, string?, string?, string?];

export function sendAnalyticsEvent(event: GameAnalyticsEvent, eventValue?: number) {
  // don't track if we're not client-side since NextJS renders the HTML on server
  if (typeof window !== 'undefined' && analyticsInitialized) {
    const app = appNameKebabCase();

    // Join the non-empty parts of the event tuple with a colon separator
    const eventDetails = event.filter(Boolean).join(':');

    // Send the event to GameAnalytics with the appended event details
    const eventName = `${app}:${eventDetails}`
    console.log('Analytics: Event: ' + eventName)
    if (eventValue !== undefined) {
      // GameAnalytics("addDesignEvent", eventName, eventValue);
      GameAnalytics.addDesignEvent(eventName, eventValue);
    } else {
      // GameAnalytics("addDesignEvent", eventName);
      GameAnalytics.addDesignEvent(eventName);
    }

    const versionName = process.env.NEXT_PUBLIC_VERSION_NAME
    amplitude.track({
      event_type: eventName,
      app_version: packageJson.version
    })

  }
}


export function setAnalyticsUserId(userId: string) {
  // GameAnalytics.configureUserId(userId);
  amplitude.setUserId(userId)
}


const Analytics = function () {
  useEffect(() => {
    if (typeof window !== 'undefined' && !analyticsInitialized) {
      amplitude.init('4a9417393c890dc8498e1a3a93a92424', { "autocapture": true });
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
  }, [])

  return <></>
}

export default Analytics

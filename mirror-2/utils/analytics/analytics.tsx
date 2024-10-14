'use client'
import packageJson from '../../package.json'
import { ampli } from '@/src/ampli'
import { sessionReplayPlugin } from '@amplitude/plugin-session-replay-browser'
import { useEffect } from 'react'

export enum AnalyticsEvent {
  /**
   * Spaces
   */
  CreateSpace = 'Create Space',
  DeleteSpace = 'Delete Space',

  /**
   * Scenes
   */
  CreateScene = 'Create Scene',
  DeleteScene = 'Delete Scene',

  /**
   * Entity
   */
  CreateEntity = 'Create Entity',
  DeleteEntity = 'Delete Entity',

  /**
   * Space Packs
   */
  CreateSpacePack = 'Create Space Pack',
  DeleteSpacePack = 'Delete Space Pack',

  /**
   * User
   */
  UserLogin = 'User Login',
  UserLogout = 'User Logout'
}

export const AnalyticsEvents = {
  spaces: {
    create: 'Create Space'
  },
  scenes: {
    create: 'Create Scene'
  },
  spacePacks: {
    create: 'Create Space Pack'
  }
} as const

if (typeof window !== 'undefined') {
  window['analyticsInitialized'] = false
}

export function sendAnalyticsEvent(event: AnalyticsEvent) {
  // don't track if we're not client-side since NextJS renders the HTML on server
  if (typeof window !== 'undefined' && window['analyticsInitialized']) {
    ampli.track({
      event_type: event,
      app_version: packageJson.version
    })
  }
}

export function setAnalyticsUserId(userId: string) {
  if (typeof window !== 'undefined' && !window['analyticsInitialized']) {
    ampli.client.setUserId(userId)
  }
}

export default function AnalyticsInitializer() {
  useEffect(() => {
    // Ensure we are in the browser and analytics has not been initialized
    if (typeof window !== 'undefined' && !window['analyticsInitialized']) {
      if (!process.env.NEXT_PUBLIC_AMPLITUDE_PUBLIC_KEY) {
        throw new Error('Missing analytics key')
      }

      ampli.load({
        client: { apiKey: process.env.NEXT_PUBLIC_AMPLITUDE_PUBLIC_KEY }
      })
      ampli.client.add(sessionReplayPlugin())

      console.log('Analytics: Initializing')

      window['analyticsInitialized'] = true
    }
  }, [])

  return null // No UI component to render
}

"use client"
import { useEffect } from 'react';
import packageJson from '../../package.json';
import { GameAnalytics } from 'gameanalytics'

export function setAnalyticsUserId(userId: string) {
  GameAnalytics("configureUserId", userId);
}

const Analytics = function () {
  useEffect(() => {
    if (typeof window !== 'undefined') {
      GameAnalytics("configureBuild", `web ${packageJson.version}`);
      GameAnalytics("initialize", process.env.NEXT_PUBLIC_GA_KEY_GAME_PUBLIC, process.env.NEXT_PUBLIC_GA_KEY_SECRET);
    }
  }, [])

  return <></>
}

export default Analytics

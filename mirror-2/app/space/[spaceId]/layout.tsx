'use client'
import { SpaceEngineProvider } from '@/components/engine/space-engine-context'
import React from 'react'

// the intent here is for a shared SpaceEngineProvider across both build and play. might be revisited/refactored in the future so they're separate but TBD
export default function SpaceLayout({
  children
}: {
  children: React.ReactNode
}) {
  return (
    <>
      {/* main engine manager for scenes, entities, etc. */}
      <SpaceEngineProvider> {children}</SpaceEngineProvider>
    </>
  )
}

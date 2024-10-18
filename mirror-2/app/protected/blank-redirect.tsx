'use client'

import { useRedirectToHomeIfSignedIn } from '@/hooks/auth'

export function BlankRedirect() {
  useRedirectToHomeIfSignedIn()
  return <> </>
}

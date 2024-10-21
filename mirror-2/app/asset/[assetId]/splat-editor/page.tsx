'use client'

import SplatEditorViewport from '@/components/engine/splat-editor-viewport'
import { useParams } from 'next/navigation'

// blank page since we're using the parallel routes for spaceViewport, controlBar, etc.
export default function Page() {
  const params = useParams<{ assetId: string }>()
  const assetId: number = parseInt(params.assetId, 10) // Use parseInt for safer conversion

  // exit, not implemented yet
  if (typeof window !== 'undefined') {
    window.location.href = '/home'
  }
  return
  // return <SplatEditorViewport assetId={assetId} />
}

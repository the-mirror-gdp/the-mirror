'use client'

import SplatEditorViewport from '@/components/engine/space-viewport-2'
import { useParams } from 'next/navigation'

// blank page since we're using the parallel routes for spaceViewport, controlBar, etc.
export default function Page() {
  const params = useParams<{ assetId: string }>()
  const assetId: number = parseInt(params.assetId, 10) // Use parseInt for safer conversion

  return <SplatEditorViewport assetId={assetId} />
}

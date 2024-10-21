'use client'
import InnerControlBar from '@/app/space/[spaceId]/build/controlBar/inner-control-bar'
import Inspector from '@/components/ui/inspector/inspector'
import { Sidebar } from '@/app/space/[spaceId]/build/sidebar'
import { TopNavbar } from '@/app/space/[spaceId]/build/top-navbar'
// import SpaceViewport from "@/components/engine/space-viewport"
import { useParams } from 'next/navigation'
// import SpaceViewport2 from "@/components/engine/space-viewport-2"
import SpaceViewport from '@/components/engine/space-viewport'
import SpaceViewport2 from '@/components/engine/space-viewport-2'

export default function Layout({
  children,
  params
}: {
  children: React.ReactNode
  spaceViewport: React.ReactNode
  params: { spaceId: string }
}) {
  const spaceId: number = parseInt(params.spaceId, 10) // Use parseInt for safer conversion
  return <SpaceViewport2 mode="build" spaceId={spaceId} />
  // <div className="h-screen max-h-screen w-screen grid grid-rows-[auto,1fr] overflow-hidden">
  {
    /* <TopNavbar /> */
  }

  // </div>
}

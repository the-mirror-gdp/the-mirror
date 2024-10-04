import Link from "next/link"

import { TopNavbar } from "@/app/space/[spaceId]/build/top-navbar"
import { ResizableHandle, ResizablePanel, ResizablePanelGroup } from "@/components/ui/resizable"
import { AppLogoImageSmall } from "@/lib/theme-service"
import { Sidebar } from "@/app/space/[spaceId]/build/sidebar"
import SpaceViewport from "@/app/space/[spaceId]/build/space-viewport"
import InnerControlBar from "@/app/space/[spaceId]/build/(controlBar)/inner-control-bar"

export default async function Layout({ children, params }: {
  children: React.ReactNode,
  spaceViewport: React.ReactNode,
  params: { spaceId: string }
}) {

  return (
    <div>
      <div className="absolute h-16 w-full">
        <TopNavbar />
      </div>
      <div className="absolute pt-16 w-32 h-full">
        <Sidebar />
      </div>
      <div className="absolute left-32 top-16 min-w-96 w-96 h-full">
        <InnerControlBar />
      </div>
      <div className="pl-32 pt-16 min-h-screen h-dvh">
        <SpaceViewport />
      </div>
    </div>
  )
}

import Link from "next/link"

import { TopNavbar } from "@/app/space/[spaceId]/build/top-navbar"
import { ResizableHandle, ResizablePanel, ResizablePanelGroup } from "@/components/ui/resizable"
import { AppLogoImageSmall } from "@/lib/theme-service"

export default function Layout({ children, controlBar, spaceViewport }: {
  children: React.ReactNode,
  controlBar: React.ReactNode,
  spaceViewport: React.ReactNode
}) {
  return (
    <ResizablePanelGroup direction="horizontal" className="grid min-h-screen w-full">
      <ResizablePanel defaultSize={20} minSize={20} maxSize={75}>
        <div className="hidden bg-muted/40 md:block h-full">
          <div className="flex h-full max-h-screen flex-col gap-2">
            <div className="flex h-14 items-center px-4 lg:h-[60px] lg:px-6">
              <Link href="/" className="flex items-center gap-2 font-semibold">
                <div className="mt-1">
                  <AppLogoImageSmall />
                </div>
              </Link>
            </div>
            {controlBar}
          </div>
        </div>
      </ResizablePanel>
      <ResizableHandle />
      <ResizablePanel>
        <div className="flex flex-col h-full content-center">
          <TopNavbar />
          {spaceViewport}
          {children}
        </div>
      </ResizablePanel>
    </ResizablePanelGroup>
  )
}

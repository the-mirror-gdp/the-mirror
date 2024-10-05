import InnerControlBar from "@/app/space/[spaceId]/build/(controlBar)/inner-control-bar"
import { Sidebar } from "@/app/space/[spaceId]/build/sidebar"
import SpaceViewport from "@/app/space/[spaceId]/build/space-viewport"
import { TopNavbar } from "@/app/space/[spaceId]/build/top-navbar"

export default async function Layout({ children, params }: {
  children: React.ReactNode,
  spaceViewport: React.ReactNode,
  params: { spaceId: string }
}) {

  return (
    <div className="h-screen w-screen grid grid-rows-[auto,1fr] overflow-hidden">
      <TopNavbar />
      <div className="grid grid-cols-[4%,1fr,5fr]">
        <Sidebar />
        <InnerControlBar />
        <SpaceViewport />
      </div>
    </div>
  )
}

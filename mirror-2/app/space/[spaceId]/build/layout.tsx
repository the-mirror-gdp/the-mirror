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
      <div className="grid grid-cols-[minmax(100px,4%),1fr,5fr]">
        <Sidebar />
        <InnerControlBar />
        <SpaceViewport />

        {/* only loading children for separate data fetching to keep this as server component */}
        {children}
      </div>
    </div>
  )
}

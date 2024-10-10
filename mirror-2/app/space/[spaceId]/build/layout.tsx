import InnerControlBar from "@/app/space/[spaceId]/build/controlBar/inner-control-bar"
import Inspector from "@/app/space/[spaceId]/build/inspector/inspector"
import { Sidebar } from "@/app/space/[spaceId]/build/sidebar"
import SpaceViewport from "@/app/space/[spaceId]/build/space-viewport"
import { TopNavbar } from "@/app/space/[spaceId]/build/top-navbar"

export default function Layout({ children, params }: {
  children: React.ReactNode,
  spaceViewport: React.ReactNode,
  params: { spaceId: string }
}) {

  return (
    <div className="h-screen max-h-screen w-screen grid grid-rows-[auto,1fr] overflow-hidden">
      <TopNavbar />
      <div className="grid grid-cols-[minmax(100px,4%),minmax(200px,3fr),10fr,minmax(200px,3fr)] h-full overflow-hidden">
        <Sidebar />
        <InnerControlBar />
        <SpaceViewport />
        <Inspector />

        {/* only loading children for separate data fetching to keep this as server component */}
        {children}
      </div>
    </div>
  );
}

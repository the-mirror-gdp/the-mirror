import InnerControlBar from "@/app/space/[spaceId]/build/controlBar/inner-control-bar"
import Inspector from "@/app/space/[spaceId]/build/inspector/inspector"
import { Sidebar } from "@/app/space/[spaceId]/build/sidebar"
import SpaceViewport from "@/state/engine/space-viewport"
import { TopNavbar } from "@/app/space/[spaceId]/build/top-navbar"

export default function Layout({ children, params }: {
  children: React.ReactNode,
  spaceViewport: React.ReactNode,
  params: { spaceId: string }
}) {
  console.log('here')

  return (
    <div className="h-screen max-h-screen w-screen grid grid-rows-[auto,1fr] overflow-hidden">
      <TopNavbar />
      {/* <div className="grid grid-cols-[250px,1fr,300px,1fr] h-full overflow-hidden"> */}
      <div className="flex h-full overflow-hidden">
        {/* Sidebar with fixed width */}
        <div className="flex-none w-24">
          <Sidebar />
        </div>

        {/* Inner control bar takes flexible space */}
        <div className="flex-initial min-w-64">
          <InnerControlBar />
        </div>

        {/* Space viewport (main content) */}
        <div className="flex-auto">
          <SpaceViewport />
        </div>

        {/* Instead of a div wrapping here, passing in className so that this component can be server compoonent; the Inspector has to use a hook for checking if entity selected */}
        <Inspector className="flex-initial min-w-96" />


        {/* Children for additional content */}
        {children}
      </div>
    </div>
  );
}

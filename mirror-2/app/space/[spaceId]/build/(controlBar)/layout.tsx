import ControlBar from '@/app/space/[spaceId]/build/(controlBar)/control-bar'
import InnerControlBar from '@/app/space/[spaceId]/build/(controlBar)/inner-control-bar'

export default function Layout({ children }: { children: React.ReactNode }) {
  return (
    <div className="flex flex-row ">
      <div className="flex-none">
        <ControlBar />
      </div>
      <div className="flex-auto">
        <InnerControlBar />
      </div>
    </div>
  )
}

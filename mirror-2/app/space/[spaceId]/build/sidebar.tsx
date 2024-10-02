import ControlBar from "@/app/space/[spaceId]/build/(controlBar)/control-bar";
import controlBar from "@/app/space/[spaceId]/build/(controlBar)/control-bar";
import { ResizablePanelGroup, ResizablePanel, ResizableHandle } from "@/components/ui/resizable";

export function Sidebar() {
  return (
    <div className="bg-muted/40 h-full">
      <ControlBar />
    </div>
  )
}

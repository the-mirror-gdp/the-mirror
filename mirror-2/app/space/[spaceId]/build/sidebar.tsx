"use client"
import ControlBar from "@/app/space/[spaceId]/build/controlBar/control-bar";

export function Sidebar() {
  return (
    <div className="bg-muted/40 h-full">
      <ControlBar />
    </div>
  )
}

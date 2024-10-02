import { cn } from "@/lib/utils"


import { Playlist } from "../data/playlists"
import { Button } from "@/components/ui/button"
import { ScrollArea } from "@/components/ui/scroll-area"
import Link from "next/link"
import { Axis3D, Gamepad2, PlusCircleIcon } from "lucide-react"

interface SidebarProps extends React.HTMLAttributes<HTMLDivElement> {
  playlists: Playlist[]
}

export function Sidebar({ className, playlists }: SidebarProps) {
  return (
    <div className={cn("pb-12", className)}>
      <div className="space-y-4 py-4">
        <div className="px-3 py-2">
          <h2 className="mb-2 px-4 text-2xl font-semibold tracking-tight">
            Discover
          </h2>
          <div className="space-y-1">
            <Button variant="secondary" className="w-full justify-start">
              <Axis3D className="mr-2" />
              Spaces
            </Button>
            {process.env.NEXT_PUBLIC_DISCORD_INVITE_URL && <Button variant="ghost" className="w-full justify-start" asChild>
              <Link href={process.env.NEXT_PUBLIC_DISCORD_INVITE_URL} target="_blank" > <Gamepad2 className="mr-2" />
                Chat on Discord</Link>
            </Button>}
            <Button className="w-full" asChild>
              <Link href="/space/new" className="w-full p-3"><PlusCircleIcon className="mr-2" />Create a Space</Link>
            </Button>
          </div>
        </div>

      </div>
    </div>
  )
}

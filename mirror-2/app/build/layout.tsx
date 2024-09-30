import Link from "next/link"
import {
  Bell,
  CircleUser,
  Home,
  LineChart,
  Menu,
  Package,
  Package2,
  Search,
  ShoppingCart,
  Users,
} from "lucide-react"

import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card"
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu"
import { Input } from "@/components/ui/input"
import { ResizableHandle, ResizablePanel, ResizablePanelGroup } from "@/components/ui/resizable"
import { Sidebar } from "@/app/build/sidebar"
import { appLogoImageSmall, appName } from "@/lib/theme-service"
import { Viewport } from "@/app/build/viewport"
import { TopNavbar } from "@/app/build/top-navbar"

export default function Dashboard({ children }: any) {
  return (
    <ResizablePanelGroup direction="horizontal" className="grid min-h-screen w-full">
      <ResizablePanel defaultSize={20} minSize={20} maxSize={75}>
        <div className="hidden bg-muted/40 md:block h-full">
          <div className="flex h-full max-h-screen flex-col gap-2">
            <div className="flex h-14 items-center px-4 lg:h-[60px] lg:px-6">
              <Link href="/" className="flex items-center gap-2 font-semibold">
                <div className="mt-1">
                  {appLogoImageSmall()}
                </div>
              </Link>
            </div>
            <Sidebar />
          </div>
        </div>
      </ResizablePanel>
      <ResizableHandle />
      <ResizablePanel>
        <div className="flex flex-col h-full content-center">
          <TopNavbar />
          <Viewport />
        </div>
      </ResizablePanel>
    </ResizablePanelGroup>
  )
}

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
import { appName } from "@/lib/copy-service"
import { Viewport } from "@/app/build/viewport"
import { TopNavbar } from "@/app/build/top-navbar"

export default function Dashboard() {
  return (
    <ResizablePanelGroup direction="horizontal" className="grid min-h-screen w-full">
      <ResizablePanel defaultSize={15} minSize={15} maxSize={75}>
        <div className="hidden bg-muted/40 md:block h-full">
          <div className="flex h-full max-h-screen flex-col gap-2">
            <div className="flex h-14 items-center px-4 lg:h-[60px] lg:px-6">
              <Link href="/" className="flex items-center gap-2 font-semibold">
                <Package2 className="h-6 w-6" />
                <div className="mr-3">{appName()}</div>
              </Link>
              <Button variant="outline" size="icon" className="ml-auto h-8 w-8">
                <Bell className="h-4 w-4" />
                <span className="sr-only">Toggle notifications</span>
              </Button>
            </div>
            <Sidebar />
          </div>
        </div>
      </ResizablePanel>
      <ResizableHandle withHandle />
      <ResizablePanel>
        <div className="flex flex-col h-full content-center">
          <TopNavbar />
          <Viewport />
        </div>
      </ResizablePanel>
    </ResizablePanelGroup>
  )
}

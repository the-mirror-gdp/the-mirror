import { cn } from '@/lib/utils'

import { Playlist } from '../data/playlists'
import { Button } from '@/components/ui/button'
import Link from 'next/link'
import { Axis3D, Gamepad2, PlusCircleIcon } from 'lucide-react'
import {
  Dialog,
  DialogClose,
  DialogContent,
  DialogOverlay,
  DialogPortal,
  DialogTrigger
} from '@/components/ui/dialog'
import './sidebar.css'

interface SidebarProps extends React.HTMLAttributes<HTMLDivElement> {
  playlists: Playlist[]
}

const SidebarMenuForSmallScreen = () => {
  return (
    <>
      <div className="space-y-3">
        <Button variant="secondary" className="w-full justify-start" asChild>
          <Link href="/home" className="w-full p-3">
            <Axis3D className="mr-2" />
            Home
          </Link>
        </Button>
        <Button variant="secondary" className="w-full justify-start" asChild>
          <Link href="/discover" className="w-full p-3">
            <Axis3D className="mr-2" />
            Discover
          </Link>
        </Button>
        <Button variant="secondary" className="w-full justify-start" asChild>
          <Link href="/my/spaces" className="w-full p-3">
            <Axis3D className="mr-2" />
            My Spaces
          </Link>
        </Button>
        <Button variant="secondary" className="w-full justify-start" asChild>
          <Link href="/my/assets" className="w-full p-3">
            <Axis3D className="mr-2" />
            My Assets
          </Link>
        </Button>
        {process.env.NEXT_PUBLIC_DISCORD_INVITE_URL && (
          <Button variant="ghost" className="w-full justify-start" asChild>
            <Link
              href={process.env.NEXT_PUBLIC_DISCORD_INVITE_URL}
              target="_blank"
            >
              {' '}
              <Gamepad2 className="mr-2" />
              Chat on Discord
            </Link>
          </Button>
        )}
        {/* <Button className="w-full" asChild>
              <Link href="/space/new" className="w-full p-3">
                <PlusCircleIcon className="mr-2" />
                Create a Space
              </Link>
            </Button> */}
      </div>
    </>
  )
}

export function Sidebar({ className, playlists, style }: SidebarProps) {
  return (
    <>
      <div
        className={cn('pb-12 hidden sm:hidden md:hidden lg:block', className)}
        style={{ ...style }}
      >
        <div className="space-y-4 py-4">
          <div className="px-3 py-2">
            <h2 className="mb-2 px-4 text-2xl font-semibold tracking-tight">
              Discover
            </h2>
            <div className="space-y-2">
              <Button
                variant="secondary"
                className="w-full justify-start"
                asChild
              >
                <Link href="/home" className="w-full p-3">
                  <Axis3D className="mr-2" />
                  Home
                </Link>
              </Button>
              <Button
                variant="secondary"
                className="w-full justify-start"
                asChild
              >
                <Link href="/discover" className="w-full p-3">
                  <Axis3D className="mr-2" />
                  Discover
                </Link>
              </Button>
              <Button
                variant="secondary"
                className="w-full justify-start"
                asChild
              >
                <Link href="/my/spaces" className="w-full p-3">
                  <Axis3D className="mr-2" />
                  My Spaces
                </Link>
              </Button>
              <Button
                variant="secondary"
                className="w-full justify-start"
                asChild
              >
                <Link href="/my/assets" className="w-full p-3">
                  <Axis3D className="mr-2" />
                  My Assets
                </Link>
              </Button>
              {process.env.NEXT_PUBLIC_DISCORD_INVITE_URL && (
                <Button
                  variant="ghost"
                  className="w-full justify-start"
                  asChild
                >
                  <Link
                    href={process.env.NEXT_PUBLIC_DISCORD_INVITE_URL}
                    target="_blank"
                  >
                    {' '}
                    <Gamepad2 className="mr-2" />
                    Chat on Discord
                  </Link>
                </Button>
              )}
              {/* <Button className="w-full" asChild>
              <Link href="/space/new" className="w-full p-3">
                <PlusCircleIcon className="mr-2" />
                Create a Space
              </Link>
            </Button> */}
            </div>
          </div>
        </div>
      </div>
      {/* =========Sidebar button for smaller screens less than 1024px======= */}
      <div className="space-y-4 py-4 mt-2 block sm:block md:block lg:hidden">
        <Dialog>
          <DialogTrigger>
            <svg
              xmlns="http://www.w3.org/2000/svg"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
              aria-hidden="true"
              className="h-5 w-5"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M4 8h16M4 16h16"
              ></path>
            </svg>{' '}
          </DialogTrigger>
          <DialogPortal>
            <DialogOverlay className="sidebar-overlay">
              <DialogContent className="sidebar-content pt-14">
                <SidebarMenuForSmallScreen />
              </DialogContent>
            </DialogOverlay>
          </DialogPortal>
        </Dialog>
      </div>
    </>
  )
}

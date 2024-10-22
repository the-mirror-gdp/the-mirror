'use client'
import { cn } from '@/lib/utils'
import { Playlist } from '../data/playlists'
import { Button } from '@/components/ui/button'
import Link from 'next/link'
import { Axis3D, Gamepad2 } from 'lucide-react'

interface SidebarProps extends React.HTMLAttributes<HTMLDivElement> {
  playlists: Playlist[]
}

export function Sidebar({ className, style }: SidebarProps) {
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
            </div>
          </div>
        </div>
      </div>
    </>
  )
}

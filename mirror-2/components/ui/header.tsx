'use client'
import React, { useState, useEffect } from 'react'
import AccountDropdownMenu from './account-dropdown-menu'
import { Button } from './button'
import Link from 'next/link'
import {
  Dialog,
  DialogTrigger,
  DialogPortal,
  DialogOverlay,
  DialogContent
} from './dialog'
import { Axis3D, Gamepad2 } from 'lucide-react'
import './header.css'

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
      </div>
    </>
  )
}

const Header = () => {
  const [windowWidth, setWindowWidth] = useState(window.innerWidth)
  const [showSmallSideBar, setShowSmallSidebar] = useState(false)

  const handleResize = () => setWindowWidth(window.innerWidth)

  useEffect(() => {
    window.addEventListener('resize', handleResize)
    return () => window.removeEventListener('resize', handleResize)
  }, [])

  useEffect(() => {
    if (windowWidth > 1024) {
      setShowSmallSidebar(false)
    }
  }, [windowWidth])

  return (
    <div className="sticky top-0 z-40">
      <header className="bg-bluenav shadow-sm lg:static lg:overflow-y-visible">
        <div className="2xl:flex 2xl:justify-center">
          <div className="lg:pl-[3.125rem] flex p-4 mobile:py-[0.8125rem] mobile:px-0 justify-between items-center mobile:flex-wrap">
            <div className="flex h-[2.5rem] items-center lg:pl-3">
              {/* =========Sidebar button for smaller screens less than 1024px======= */}
              <div className="space-y-4 py-4 mt-2 sm:block md:block lg:hidden">
                <Dialog
                  open={showSmallSideBar}
                  onOpenChange={setShowSmallSidebar}
                >
                  <DialogTrigger
                    onClick={() => setShowSmallSidebar(true)}
                    className="p-2"
                  >
                    <Button
                      type="button"
                      className="flex justify-center max-h-[3.125rem] items-center whitespace-nowrap p-3 bg-blueMirror rounded-xl font-primary font-semibold border border-transparent text-white shadow-[0_2px_40px_0px_rgba(57,121,255,0.4)]  min-w-fit mobile:text-xs bg-transparent hover:bg-transparent focus:ring-0 focus:ring-offset-0 focus:ring-transparent lg:hidden ml-1 hover:bg-blue-700 hover:ease-in duration-100 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-400"
                    >
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
                    </Button>
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
              {/* ====================================== */}
              <Link href={'/home'} className="mobile:p-0">
                <img
                  className="object-cover h-10 px-3 w-54 lg:block"
                  src="/mirror_logo_white_sm.png"
                  alt="The Mirror logo"
                />
              </Link>
            </div>
            <AccountDropdownMenu />
          </div>
        </div>
      </header>
    </div>
  )
}

export default Header

import React from 'react'
import { Separator } from '@/components/ui/separator'
import { Sidebar } from '@/app/home/components/sidebar'
import { playlists } from '@/app/home/data/playlists'
import EditButton from './components/editButton'
import { Dialog, DialogContent, DialogTrigger } from '@/components/ui/dialog'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import ResetPassword from '@/app/protected/reset-password/page'
import ResetEmail from '@/app/protected/reset-email/page'
import './page.css'
import Header from '@/components/ui/header'

const MyAccount = () => {
  return (
    <>
      <Header />
      <div className="bg-background flex">
        <Sidebar
          playlists={playlists}
          style={{
            width: '25%'
          }}
        />
        <div
          className="py-6 px-6 w-full setting-container"
          style={{
            maxWidth: '50%'
          }}
        >
          <div className="space-y-1 lg:text-left md:text-center sm:text-center text-center">
            <h2 className="text-3xl font-semibold tracking-tight">
              Account Settings
            </h2>
          </div>
          <Separator className="my-4" />
          <div className="flex items-center gap-2 mobile:gap-1 w-full justify-between">
            <div className="flex relative">
              <div className="flex-wrap mt-1 rounded-md shadow-sm">
                <Input
                  type="email"
                  name="email"
                  className="block h-[3.125rem] rounded-xl focus:outline-none pt-6 pl-4 text-white text-base font-semibold font-primary border-gray-700 text-disabledMirror focus:border-ringBlue border-none bg-transparent"
                  value={'tarun@themirror.space'}
                  readOnly
                />
                <Label
                  htmlFor="email"
                  className="absolute left-4 top-2 text-textInput text-xs font-semibold font-primary peer-placeholder-shown:text-sm peer-focus:text-xs"
                >
                  Email
                </Label>
              </div>
            </div>
            <Dialog>
              <DialogTrigger asChild>
                <EditButton />
              </DialogTrigger>
              <DialogContent>
                <ResetEmail searchParams={{ message: '' }} />
              </DialogContent>
            </Dialog>
          </div>
          <div className="flex items-center gap-2 mobile:gap-1 w-full justify-between mt-4">
            <div className="flex relative">
              <div className="flex-wrap mt-1 rounded-md shadow-sm">
                <Input
                  type="password"
                  name="password"
                  value="tarun@themirror.space"
                  className="block h-[3.125rem] rounded-xl focus:outline-none pt-6 pl-4 text-white text-base font-semibold font-primary border-gray-700 text-disabledMirror focus:border-ringBlue border-none bg-transparent"
                  readOnly
                />
                <Label
                  htmlFor="password"
                  className="absolute left-4 top-2 text-textInput text-xs font-semibold font-primary peer-placeholder-shown:text-sm peer-focus:text-xs"
                >
                  Password
                </Label>
              </div>
            </div>
            <Dialog>
              <DialogTrigger asChild>
                <EditButton />
              </DialogTrigger>
              <DialogContent>
                <ResetPassword searchParams={{ message: '' }} />
              </DialogContent>
            </Dialog>
          </div>
        </div>
      </div>
    </>
  )
}

export default MyAccount

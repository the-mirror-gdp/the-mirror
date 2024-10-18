'use client'
import React from 'react'
import { Card, CardContent, CardFooter } from '@/components/ui/card'
import Image from 'next/image'
import { Sidebar } from '../../home/components/sidebar'
import { playlists } from '../../home/data/playlists'
import { Separator } from '@/components/ui/separator'
import Link from 'next/link'
import { Button } from '@/components/ui/button'
import { PlusCircleIcon } from 'lucide-react'
import { useGetSpacesByUserIdQuery } from '@/state/api/spaces'
import { useRedirectToLoginIfNotSignedIn } from '@/hooks/auth'

const dummyImg =
  'https://images.unsplash.com/photo-1615247001958-f4bc92fa6a4a?w=300&dpr=2&q=80'

const MySpaces = () => {
  useRedirectToLoginIfNotSignedIn()
  const { data: spaces, error } = useGetSpacesByUserIdQuery('')

  return (
    <div className="bg-background flex">
      <Sidebar
        playlists={playlists}
        style={{
          width: '25%'
        }}
      />
      <div className="py-6 px-6 w-full">
        <div className="flex items-center justify-between">
          <div className="space-y-1">
            <h2 className="text-3xl font-semibold tracking-tight">My Spaces</h2>
          </div>
          <div className="ml-auto mr-4">
            <Button className="w-full" asChild>
              <Link href="/space/new" className="w-full p-3">
                <PlusCircleIcon className="mr-2" />
                Create a Space
              </Link>
            </Button>
          </div>
        </div>
        <Separator className="my-4" />
        {spaces?.length ? (
          <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-4">
            {spaces?.map((space) => (
              <Card
                key={space?.name}
                className="rounded-none"
                style={{
                  borderBottomLeftRadius: '0.75rem',
                  borderBottomRightRadius: '0.75rem'
                }}
              >
                <CardContent className="p-0">
                  <Image
                    src={dummyImg}
                    width={250}
                    height={250}
                    alt={space?.name}
                    style={{
                      height: '250px',
                      width: '100%'
                    }}
                  />
                </CardContent>
                <CardFooter>
                  <div className="space-y-1 text-lg mt-4">
                    <h3 className="font-medium leading-none">{space?.name}</h3>
                    <p className="text-xs text-muted-foreground">
                      Created At {space?.created_at.split('T')[0]}
                    </p>
                  </div>
                </CardFooter>
              </Card>
            ))}
          </div>
        ) : (
          <h3 className="text-center">No Space found</h3>
        )}
      </div>
    </div>
  )
}

export default MySpaces

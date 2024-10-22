import React from 'react'
import { listenNowAlbums, madeForYouAlbums } from '../home/data/albums'
import { Card, CardContent, CardFooter } from '@/components/ui/card'
import Image from 'next/image'
import { Sidebar } from '../home/components/sidebar'
import { playlists } from '../home/data/playlists'
import { Separator } from '@/components/ui/separator'
import { Metadata } from 'next'
import Header from '@/components/ui/header'

export const metadata: Metadata = {
  title: 'Discover',
  description: ''
}
const Discover = () => {
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
        <div className="py-6 px-6 w-full">
          <div className="space-y-1">
            <h2 className="text-3xl font-semibold tracking-tight">Discover</h2>
          </div>
          <Separator className="my-4" />
          {listenNowAlbums.length ? (
            <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-4">
              {listenNowAlbums?.map((album) => (
                <Card
                  key={album?.name}
                  className="rounded-none"
                  style={{
                    borderBottomLeftRadius: '0.75rem',
                    borderBottomRightRadius: '0.75rem'
                  }}
                >
                  <CardContent className="p-0">
                    <Image
                      src={album?.cover}
                      width={250}
                      height={250}
                      alt={album?.name}
                      style={{
                        height: '250px',
                        width: '100%'
                      }}
                    />
                  </CardContent>
                  <CardFooter>
                    <div className="space-y-1 text-lg mt-4">
                      <h3 className="font-medium leading-none">{album.name}</h3>
                      <p className="text-xs text-muted-foreground">
                        {album.artist}
                      </p>
                    </div>
                  </CardFooter>
                </Card>
              ))}
            </div>
          ) : (
            <h3>No Item found</h3>
          )}
        </div>
      </div>
    </>
  )
}

export default Discover

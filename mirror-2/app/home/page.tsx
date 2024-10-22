'use client'
import Image from 'next/image'
import { Sidebar } from './components/sidebar'
import { listenNowAlbums, madeForYouAlbums } from './data/albums'
import { playlists } from './data/playlists'
import { Separator } from '@/components/ui/separator'
import { appDescription, appName } from '@/lib/theme-service'
import AccountDropdownMenu from '@/components/ui/account-dropdown-menu'
import { Card, CardContent, CardFooter } from '@/components/ui/card'
import { useGetSpacesByUserIdQuery } from '@/state/api/spaces'
import Header from '@/components/ui/header'

const dummyImg =
  'https://images.unsplash.com/photo-1513745405825-efaf9a49315f?w=300&dpr=2&q=80'

export default function Home() {
  const { data: spaces, error } = useGetSpacesByUserIdQuery('')

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
          <div>
            <div className="flex items-center justify-between">
              <div className="space-y-1">
                <h2 className="text-2xl font-semibold tracking-tight">
                  Popular
                </h2>
                <p className="text-sm text-muted-foreground">
                  Published Spaces from other builders.
                </p>
              </div>
            </div>
            <Separator className="my-4" />
            <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-4">
              {madeForYouAlbums.slice(0, 4).map((album) => (
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
          </div>
          <div className="py-6">
            <div className="flex items-center justify-between">
              <div className="space-y-1">
                <h2 className="text-2xl font-semibold tracking-tight">
                  My Spaces
                </h2>
                <p className="text-sm text-muted-foreground">
                  Spaces created by you.
                </p>
              </div>
            </div>
            {spaces?.length ? (
              <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-4 py-6">
                {spaces?.slice(0, 4).map((space) => (
                  <Card
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
                        <h3 className="font-medium leading-none">
                          {space?.name}
                        </h3>
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
      </div>
    </>
  )
}

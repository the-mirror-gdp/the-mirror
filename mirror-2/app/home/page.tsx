import Image from "next/image";
import { Sidebar } from "./components/sidebar";
import { listenNowAlbums, madeForYouAlbums } from "./data/albums";
import { playlists } from "./data/playlists";
import { Separator } from "@/components/ui/separator";
import { appDescription, appName } from "@/lib/theme-service";
import { Metadata } from "next";
import AccountDropdownMenu from "@/components/ui/account-dropdown-menu";
import { Card, CardContent, CardFooter } from "@/components/ui/card";

export const metadata: Metadata = {
  title: "The Mirror",
  description: "",
};
export default function Home() {
  return (
    <>
      <div className="md:hidden hidden">
        <Image
          src="/examples/music-light.png"
          width={1280}
          height={1114}
          alt="Music"
          className="block dark:hidden"
        />
        <Image
          src="/examples/music-dark.png"
          width={1280}
          height={1114}
          alt="Music"
          className="hidden dark:block"
        />
      </div>
      <div className="bg-background flex">
        <Sidebar
          playlists={playlists}
          className="hidden lg:block w "
          style={{
            width: "25%",
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
              <AccountDropdownMenu />
            </div>
            <Separator className="my-4" />
            <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-4">
              {madeForYouAlbums.slice(0, 4).map((album) => (
                <Card
                  className="rounded-none"
                  style={{
                    borderBottomLeftRadius: "0.75rem",
                    borderBottomRightRadius: "0.75rem",
                  }}
                >
                  <CardContent className="p-0">
                    <Image
                      src={album?.cover}
                      width={250}
                      height={250}
                      alt={album?.name}
                      style={{
                        height: "250px",
                        width: "100%",
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

            <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-4 py-6">
              {madeForYouAlbums.slice(0, 4).map((album) => (
                <Card
                  className="rounded-none"
                  style={{
                    borderBottomLeftRadius: "0.75rem",
                    borderBottomRightRadius: "0.75rem",
                  }}
                >
                  <CardContent className="p-0">
                    <Image
                      src={album?.cover}
                      width={250}
                      height={250}
                      alt={album?.name}
                      style={{
                        height: "250px",
                        width: "100%",
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
        </div>
      </div>
    </>
  );
}

import { Sidebar } from '@/app/home/components/sidebar'
import { madeForYouAlbums } from '@/app/home/data/albums'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardFooter } from '@/components/ui/card'
import Header from '@/components/ui/header'
import { Tabs, TabsList, TabsTrigger, TabsContent } from '@/components/ui/tabs'
import Image from 'next/image'
import Link from 'next/link'
import React from 'react'

const dummyImg =
  'https://images.unsplash.com/photo-1615247001958-f4bc92fa6a4a?w=300&dpr=2&q=80'

const getSpaces = () => {
  return madeForYouAlbums?.length ? (
    <>
      <h1 className="text-3xl mb-8 mt-8 font-bold ">{`${madeForYouAlbums.length} Spaces`}</h1>
      <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-4">
        {madeForYouAlbums?.map((space) => (
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
                  Created At {space?.created_at?.split('T')[0] || '1-10-2014'}
                </p>
              </div>
            </CardFooter>
          </Card>
        ))}
      </div>
    </>
  ) : (
    <h3 className="text-center">No Space found</h3>
  )
}

const getAssets = () => {
  return madeForYouAlbums?.length ? (
    <>
      <h1 className="text-3xl mb-8 mt-8 font-bold ">{`${madeForYouAlbums.length} Assets`}</h1>
      <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-4">
        {madeForYouAlbums?.map((space) => (
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
                  Created At {space?.created_at?.split('T')[0] || '1-10-2014'}
                </p>
              </div>
            </CardFooter>
          </Card>
        ))}
      </div>
    </>
  ) : (
    <h3 className="text-center">No Asset found</h3>
  )
}

const bannerSection = () => {
  return (
    <div
      className="w-full min-h-[25rem] rounded-xl bg-cover flex flex-col justify-end -mt-3.5"
      style={{
        backgroundImage: `url(
                'https://storage.googleapis.com/the-mirror-backend-dev-asset-uploads-public/648747ab1671751177be7f26/profile-images/648a0d2b6c10072e37cca3e3.png'
              )`
      }}
    >
      <div className="min-h-[12rem] flex flex-col justify-between items-start rounded-xl backdrop-blur bgform m-5 p-4 g-4 relative lt-lg:flex-wrap xl:items-end xl:flex-row mobile:items-center">
        <div className="flex items-center gap-5 mobile:flex-col mobile:gap-0">
          <div className="flex-none">
            <img
              alt="profile-image"
              src="https://storage.googleapis.com/the-mirror-backend-dev-asset-uploads-public/648747ab1671751177be7f26/profile-images/657ad14565d060d600900b81.png"
              className="rounded-full w-[9.375rem] h-[9.375rem] object-cover cursor-pointer ring-1 ring-greenMirror p-1"
            />
          </div>
          <div className="flex flex-col gap-2 max-w-[30rem] p-2 mobile:items-center">
            <h2 className="text-break font-primary text-white font-bold lg:text-[1.8rem] lg:leading-[2.25rem] xl:leading-[3rem] leading-tight xl:text-[2.5rem] md:text-[2rem] mobile:text-[2rem]">
              Tarun
            </h2>
            <p className="text-greenMirror font-bold font-primary text-xs uppercase">
              In The Mirror Since 2023
            </p>
            <p className="text-white mobile:text-center">
              Hey, it's me. Your friendly neighborhood spiderman.
            </p>
          </div>
        </div>
        <div className="w-full xl:w-auto">
          <div className="flex flex-wrap gap-2 py-3 justify-center sm:justify-end">
            <Link
              type="button"
              rel="noreferrer"
              target="_blank"
              href="https://twitter.com/tweetmeadDSs"
              className="font-normal rounded-full outline-none focus:outline-none"
            >
              <svg
                aria-hidden="true"
                focusable="false"
                data-prefix="fab"
                data-icon="twitter"
                className="svg-inline--fa fa-twitter fa-2x transition h-6 w-6 m-1 duration-100 ease-in-out fill-current cursor-pointer text-[#6F767E] dark:text-gray-400 hover:text-blue-500 dark:hover:text-blue-500"
                role="img"
                xmlns="http://www.w3.org/2000/svg"
                viewBox="0 0 512 512"
              >
                <path
                  fill="currentColor"
                  d="M459.37 151.716c.325 4.548.325 9.097.325 13.645 0 138.72-105.583 298.558-298.558 298.558-59.452 0-114.68-17.219-161.137-47.106 8.447.974 16.568 1.299 25.34 1.299 49.055 0 94.213-16.568 130.274-44.832-46.132-.975-84.792-31.188-98.112-72.772 6.498.974 12.995 1.624 19.818 1.624 9.421 0 18.843-1.3 27.614-3.573-48.081-9.747-84.143-51.98-84.143-102.985v-1.299c13.969 7.797 30.214 12.67 47.431 13.319-28.264-18.843-46.781-51.005-46.781-87.391 0-19.492 5.197-37.36 14.294-52.954 51.655 63.675 129.3 105.258 216.365 109.807-1.624-7.797-2.599-15.918-2.599-24.04 0-57.828 46.782-104.934 104.934-104.934 30.213 0 57.502 12.67 76.67 33.137 23.715-4.548 46.456-13.32 66.599-25.34-7.798 24.366-24.366 44.833-46.132 57.827 21.117-2.273 41.584-8.122 60.426-16.243-14.292 20.791-32.161 39.308-52.628 54.253z"
                ></path>
              </svg>
            </Link>
            <Link
              type="button"
              rel="noreferrer"
              target="_blank"
              href="https://instagram.com/itsmetk"
              className="font-normal rounded-full outline-none focus:outline-none"
            >
              <svg
                aria-hidden="true"
                focusable="false"
                data-prefix="fab"
                data-icon="instagram"
                className="svg-inline--fa fa-instagram fa-2x transition h-6 w-6 m-1 duration-100 ease-in-out fill-current cursor-pointer text-[#6F767E] dark:text-gray-400 hover:text-orange-400 dark:hover:text-orange-400"
                role="img"
                xmlns="http://www.w3.org/2000/svg"
                viewBox="0 0 448 512"
              >
                <path
                  fill="currentColor"
                  d="M224.1 141c-63.6 0-114.9 51.3-114.9 114.9s51.3 114.9 114.9 114.9S339 319.5 339 255.9 287.7 141 224.1 141zm0 189.6c-41.1 0-74.7-33.5-74.7-74.7s33.5-74.7 74.7-74.7 74.7 33.5 74.7 74.7-33.6 74.7-74.7 74.7zm146.4-194.3c0 14.9-12 26.8-26.8 26.8-14.9 0-26.8-12-26.8-26.8s12-26.8 26.8-26.8 26.8 12 26.8 26.8zm76.1 27.2c-1.7-35.9-9.9-67.7-36.2-93.9-26.2-26.2-58-34.4-93.9-36.2-37-2.1-147.9-2.1-184.9 0-35.8 1.7-67.6 9.9-93.9 36.1s-34.4 58-36.2 93.9c-2.1 37-2.1 147.9 0 184.9 1.7 35.9 9.9 67.7 36.2 93.9s58 34.4 93.9 36.2c37 2.1 147.9 2.1 184.9 0 35.9-1.7 67.7-9.9 93.9-36.2 26.2-26.2 34.4-58 36.2-93.9 2.1-37 2.1-147.8 0-184.8zM398.8 388c-7.8 19.6-22.9 34.7-42.6 42.6-29.5 11.7-99.5 9-132.1 9s-102.7 2.6-132.1-9c-19.6-7.8-34.7-22.9-42.6-42.6-11.7-29.5-9-99.5-9-132.1s-2.6-102.7 9-132.1c7.8-19.6 22.9-34.7 42.6-42.6 29.5-11.7 99.5-9 132.1-9s102.7-2.6 132.1 9c19.6 7.8 34.7 22.9 42.6 42.6 11.7 29.5 9 99.5 9 132.1s2.7 102.7-9 132.1z"
                ></path>
              </svg>
            </Link>
            <Link
              type="button"
              rel="noreferrer"
              target="_blank"
              href="https://youtube.com/adaasdnnn"
              className="font-normal rounded-full outline-none focus:outline-none"
            >
              <svg
                aria-hidden="true"
                focusable="false"
                data-prefix="fab"
                data-icon="youtube"
                className="svg-inline--fa fa-youtube fa-2x transition h-6 w-6 m-1 duration-100 ease-in-out fill-current cursor-pointer text-[#6F767E] dark:text-gray-400 hover:text-red-600 dark:hover:text-red-600"
                role="img"
                xmlns="http://www.w3.org/2000/svg"
                viewBox="0 0 576 512"
              >
                <path
                  fill="currentColor"
                  d="M549.655 124.083c-6.281-23.65-24.787-42.276-48.284-48.597C458.781 64 288 64 288 64S117.22 64 74.629 75.486c-23.497 6.322-42.003 24.947-48.284 48.597-11.412 42.867-11.412 132.305-11.412 132.305s0 89.438 11.412 132.305c6.281 23.65 24.787 41.5 48.284 47.821C117.22 448 288 448 288 448s170.78 0 213.371-11.486c23.497-6.321 42.003-24.171 48.284-47.821 11.412-42.867 11.412-132.305 11.412-132.305s0-89.438-11.412-132.305zm-317.51 213.508V175.185l142.739 81.205-142.739 81.201z"
                ></path>
              </svg>
            </Link>
            <Link
              type="button"
              rel="noreferrer"
              target="_blank"
              href="https://github.com/tarunsoftprodigy"
              className="font-normal rounded-full outline-none focus:outline-none"
            >
              <svg
                aria-hidden="true"
                focusable="false"
                data-prefix="fab"
                data-icon="github"
                className="svg-inline--fa fa-github fa-2x transition h-6 w-6 m-1 duration-100 ease-in-out fill-current cursor-pointer text-[#6F767E] dark:text-gray-400 hover:text-black dark:hover:text-black"
                role="img"
                xmlns="http://www.w3.org/2000/svg"
                viewBox="0 0 496 512"
              >
                <path
                  fill="currentColor"
                  d="M165.9 397.4c0 2-2.3 3.6-5.2 3.6-3.3.3-5.6-1.3-5.6-3.6 0-2 2.3-3.6 5.2-3.6 3-.3 5.6 1.3 5.6 3.6zm-31.1-4.5c-.7 2 1.3 4.3 4.3 4.9 2.6 1 5.6 0 6.2-2s-1.3-4.3-4.3-5.2c-2.6-.7-5.5.3-6.2 2.3zm44.2-1.7c-2.9.7-4.9 2.6-4.6 4.9.3 2 2.9 3.3 5.9 2.6 2.9-.7 4.9-2.6 4.6-4.6-.3-1.9-3-3.2-5.9-2.9zM244.8 8C106.1 8 0 113.3 0 252c0 110.9 69.8 205.8 169.5 239.2 12.8 2.3 17.3-5.6 17.3-12.1 0-6.2-.3-40.4-.3-61.4 0 0-70 15-84.7-29.8 0 0-11.4-29.1-27.8-36.6 0 0-22.9-15.7 1.6-15.4 0 0 24.9 2 38.6 25.8 21.9 38.6 58.6 27.5 72.9 20.9 2.3-16 8.8-27.1 16-33.7-55.9-6.2-112.3-14.3-112.3-110.5 0-27.5 7.6-41.3 23.6-58.9-2.6-6.5-11.1-33.3 2.6-67.9 20.9-6.5 69 27 69 27 20-5.6 41.5-8.5 62.8-8.5s42.8 2.9 62.8 8.5c0 0 48.1-33.6 69-27 13.7 34.7 5.2 61.4 2.6 67.9 16 17.7 25.8 31.5 25.8 58.9 0 96.5-58.9 104.2-114.8 110.5 9.2 7.9 17 22.9 17 46.4 0 33.7-.3 75.4-.3 83.6 0 6.5 4.6 14.4 17.3 12.1C428.2 457.8 496 362.9 496 252 496 113.3 383.5 8 244.8 8zM97.2 352.9c-1.3 1-1 3.3.7 5.2 1.6 1.6 3.9 2.3 5.2 1 1.3-1 1-3.3-.7-5.2-1.6-1.6-3.9-2.3-5.2-1zm-10.8-8.1c-.7 1.3.3 2.9 2.3 3.9 1.6 1 3.6.7 4.3-.7.7-1.3-.3-2.9-2.3-3.9-2-.6-3.6-.3-4.3.7zm32.4 35.6c-1.6 1.3-1 4.3 1.3 6.2 2.3 2.3 5.2 2.6 6.5 1 1.3-1.3.7-4.3-1.3-6.2-2.2-2.3-5.2-2.6-6.5-1zm-11.4-14.7c-1.6 1-1.6 3.6 0 5.9 1.6 2.3 4.3 3.3 5.6 2.3 1.6-1.3 1.6-3.9 0-6.2-1.4-2.3-4-3.3-5.6-2z"
                ></path>
              </svg>
            </Link>
            <Link
              type="button"
              rel="noreferrer"
              target="_blank"
              href="https://artstation.com/tkd@artstation"
              className="font-normal rounded-full outline-none focus:outline-none"
            >
              <svg
                aria-hidden="true"
                focusable="false"
                data-prefix="fab"
                data-icon="artstation"
                className="svg-inline--fa fa-artstation fa-2x transition h-6 w-6 m-1 duration-100 ease-in-out fill-current cursor-pointer text-[#6F767E] dark:text-gray-400 hover:text-blue-700 dark:hover:text-blue-700"
                role="img"
                xmlns="http://www.w3.org/2000/svg"
                viewBox="0 0 512 512"
              >
                <path
                  fill="currentColor"
                  d="M2 377.4l43 74.3A51.35 51.35 0 0 0 90.9 480h285.4l-59.2-102.6zM501.8 350L335.6 59.3A51.38 51.38 0 0 0 290.2 32h-88.4l257.3 447.6 40.7-70.5c1.9-3.2 21-29.7 2-59.1zM275 304.5l-115.5-200L44 304.5z"
                ></path>
              </svg>
            </Link>
          </div>
        </div>
      </div>
    </div>
  )
}

const UserProfile = () => {
  return (
    <>
      <Header />
      <div className="bg-background flex">
        <Sidebar
          style={{
            width: '25%'
          }}
        />
        <div className="py-6 px-6 w-full">
          {bannerSection()}
          <div className="py-6 pt-10">
            <Tabs className="TabsRoot" defaultValue="space">
              <TabsList
                className="TabsList w-full justify-start py-6"
                aria-label="Manage your account"
              >
                <TabsTrigger className="TabsTrigger mx-1 text-lg" value="space">
                  SPACES
                </TabsTrigger>
                <TabsTrigger className="TabsTrigger text-lg" value="store">
                  STORE
                </TabsTrigger>
              </TabsList>

              <TabsContent className="TabsContent mt-6" value="space">
                {getSpaces()}
              </TabsContent>
              <TabsContent className="TabsContent mt-6" value="store">
                {getAssets()}
              </TabsContent>
            </Tabs>
          </div>
        </div>
      </div>
    </>
  )
}

export default UserProfile

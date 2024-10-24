import { Sidebar } from '@/app/home/components/sidebar'
import Header from '@/components/ui/header'
import React from 'react'

const SpaceDetail = () => {
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
          <h1>Space Detail</h1>
        </div>
      </div>
    </>
  )
}

export default SpaceDetail

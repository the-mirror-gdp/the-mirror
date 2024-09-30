'use client'

import { Provider } from 'jotai'

export const Providers = ({ children }: any) => {
  return (
    <Provider>
      {children}
    </Provider>
  )
}

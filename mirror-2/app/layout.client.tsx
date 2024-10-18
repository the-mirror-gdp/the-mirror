'use client'
import { ThemeProvider } from 'next-themes'
import { useSetupAuthEvents } from '@/hooks/auth'
import StoreProvider from '@/state/store.provider'

export default function ClientLayout({ children }) {
  return (
    <StoreProvider>
      <ThemeProvider
        attribute="class"
        defaultTheme="system"
        enableSystem
        disableTransitionOnChange
      >
        <InitAuthLayout children={children} />
      </ThemeProvider>
    </StoreProvider>
  )
}

// separate component here because auth setup needs to be within the store
export function InitAuthLayout({ children }) {
  useSetupAuthEvents()
  return <main className="items-center h-full">{children}</main>
}

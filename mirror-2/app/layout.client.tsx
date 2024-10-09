"use client"
import { store } from "@/state/store";
import { Provider } from 'react-redux'
import { ThemeProvider } from "next-themes";
import { useSetupAuthEvents } from "@/hooks/auth";

export default function ClientLayout({ children }) {
  return (
    <Provider store={store}>
      <ThemeProvider
        attribute="class"
        defaultTheme="system"
        enableSystem
        disableTransitionOnChange
      >
        <AuthLayout children={children} />
      </ThemeProvider>
    </Provider>
  )
}

// separate component here because auth setup needs to be within the store
export function AuthLayout({ children }) {
  useSetupAuthEvents()
  return (
    <main className="items-center h-full">
      {children}
    </main>

  )
}

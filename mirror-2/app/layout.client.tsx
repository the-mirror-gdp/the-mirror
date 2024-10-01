import { store } from "@/state/store";
import { Provider } from 'react-redux'
import { ThemeProvider } from "next-themes";

export default function ClientLayout({ children }) {
  return (
    <Provider store={store}>
      <ThemeProvider
        attribute="class"
        defaultTheme="system"
        enableSystem
        disableTransitionOnChange
      >
        <main className="min-h-screen flex flex-col items-center">
          <div className="flex-1 w-full">
            {children}
          </div>
        </main>
      </ThemeProvider>
    </Provider>
  )
}

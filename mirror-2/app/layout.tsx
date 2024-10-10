import ClientLayout from "@/app/layout.client";
import { Montserrat } from 'next/font/google'
import "./globals.css";
import { Metadata } from "next";
import { appName, appDescription, faviconPath } from "@/lib/theme-service";
import Analytics from "@/utils/analytics/analytics";


export const metadata: Metadata = {
  title: appName(),
  description: appDescription(),
}

const montserrat = Montserrat({
  subsets: ['latin'],
  display: 'swap',
})
export default function RootLayout({
  children,
}) {
  return (
    <html lang="en" className={montserrat.className} suppressHydrationWarning>
      <head>
        <link rel="icon" href={faviconPath()} sizes="any" />
      </head>
      <body className="h-screen bg-background text-foreground ">
        <Analytics />
        <ClientLayout>
          {children}
        </ClientLayout>
      </body>
    </html >
  )
}

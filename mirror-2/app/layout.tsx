
import ClientLayout from "@/app/layout.client";
import { GeistSans } from "geist/font/sans";
import "./globals.css";
import { Metadata } from "next";
import { appName, appDescription } from "@/lib/theme-service";
export const metadata: Metadata = {
  title: appName(),
  description: appDescription(),
}
export default function RootLayout({
  children,
}) {
  return (
    <html lang="en" className={GeistSans.className} suppressHydrationWarning>
      <body className="bg-background text-foreground">
        <ClientLayout>
          {children}
        </ClientLayout>
      </body>
    </html >
  )
}

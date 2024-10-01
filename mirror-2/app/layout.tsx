"use client"
import ClientLayout from "@/app/layout.client";
import { GeistSans } from "geist/font/sans";
import "./globals.css";

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

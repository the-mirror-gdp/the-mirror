"use client"
import { Button } from "@/components/ui/button";
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuLabel, DropdownMenuSeparator, DropdownMenuTrigger } from "@/components/ui/dropdown-menu";
import { signOut } from "@/hooks/auth";
import { useAppSelector } from "@/hooks/hooks";
import { selectLocalUser } from "@/state/local";
import { CircleUser } from "lucide-react";
import Link from "next/link";

export default function AccountDropdownMenu() {
  const localUserState = useAppSelector(selectLocalUser)

  return (<DropdownMenu>
    <DropdownMenuTrigger asChild>
      <Button variant="secondary" size="icon" className="rounded-full">
        <CircleUser className="h-5 w-5" />
        <span className="sr-only">Toggle user menu</span>
      </Button>
    </DropdownMenuTrigger>
    <DropdownMenuContent align="end">
      <DropdownMenuLabel>{localUserState?.email || "Welcome"}</DropdownMenuLabel>
      <DropdownMenuSeparator />
      {process.env.NEXT_PUBLIC_DISCORD_INVITE_URL && <DropdownMenuItem className="cursor-pointer"><Link href={process.env.NEXT_PUBLIC_DISCORD_INVITE_URL} target="_blank" >Chat on Discord</Link></DropdownMenuItem>}
      <DropdownMenuSeparator />
      <DropdownMenuItem onClick={() => signOut()} className="cursor-pointer">
        Logout
      </DropdownMenuItem>
    </DropdownMenuContent>
  </DropdownMenu>)
}

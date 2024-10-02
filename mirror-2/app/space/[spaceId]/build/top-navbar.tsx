"use client"
import { EditableSpaceName } from "@/components/editable-space-name";
import { ThemeSwitcher } from "@/components/theme-switcher";
import { Button } from "@/components/ui/button";
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuLabel, DropdownMenuSeparator, DropdownMenuTrigger } from "@/components/ui/dropdown-menu";
import { signOutAction } from "@/hooks/auth";
import { useAppSelector } from "@/hooks/hooks";
import { selectLocalUserState } from "@/state/local";
import { CircleUser } from "lucide-react";
import Link from "next/link";
import { useEffect, useState } from "react";

export function TopNavbar() {
  const localUserState = useAppSelector(selectLocalUserState)
  const [hasMounted, setHasMounted] = useState(false);

  // Check if the component is fully mounted (client-side)
  useEffect(() => {
    setHasMounted(true);
  }, []);
  return (
    <header className="flex h-14 items-center gap-4 bg-muted/40 px-4 lg:h-[60px] lg:px-6">
      <div className="w-full flex-1 flex items-center gap-4">
        <EditableSpaceName />
      </div>
      <ThemeSwitcher />
      {hasMounted && !localUserState?.id && <Button
        asChild
        size="sm"
        variant={"outline"}
        className="opacity-75"
      >
        <Link href="/create-account">Create Account</Link>
      </Button>}
      <DropdownMenu>
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
          <DropdownMenuItem onClick={() => signOutAction()} className="cursor-pointer">
            Logout
          </DropdownMenuItem>
        </DropdownMenuContent>
      </DropdownMenu>
    </header>
  );
}

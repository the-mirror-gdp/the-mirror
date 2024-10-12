"use client"
import { EditableSpaceName } from "@/components/editable-space-name";
import { ThemeSwitcher } from "@/components/theme-switcher";
import AccountDropdownMenu from "@/components/ui/account-dropdown-menu";
import { Button } from "@/components/ui/button";
import { useAppSelector } from "@/hooks/hooks";
import { AppLogoImageSmall } from "@/lib/theme-service";
import { selectLocalUser } from "@/state/local";
import { Play } from "lucide-react";
import Link from "next/link";
import { useParams } from "next/navigation";
import { useEffect, useState } from "react";

export function TopNavbar() {
  const localUserState = useAppSelector(selectLocalUser)
  const [hasMounted, setHasMounted] = useState(false);
  const params = useParams<{ spaceId: string }>()

  // Check if the component is fully mounted (client-side)
  useEffect(() => {
    setHasMounted(true);
  }, []);

  return (
    <header className="flex h-16 items-center gap-4 bg-muted/40 px-4  lg:px-6">
      <Link href="/home" className="flex items-center gap-2 font-semibold">
        <div className="mt-1">
          <AppLogoImageSmall />
        </div>
      </Link>
      <div className="w-full flex-1 flex items-center gap-4">
        <EditableSpaceName />
      </div>
      <ThemeSwitcher />
      {hasMounted &&
        <>
          <Button
            asChild
            variant={"outlineAccent"}
            className="hover:text-white"

          >
            <Link href={`/space/${params.spaceId}/play`} prefetch={true}><Play className="mr-2 text-white" />
              Preview
            </Link>
          </Button>
          {!localUserState?.id && <Button
            asChild
            size="sm"
            variant={"outline"}
            className="opacity-75"
          >
            <Link href="/create-account">Create Account</Link>
          </Button>}
        </>
      }
      <AccountDropdownMenu />
    </header>
  );
}

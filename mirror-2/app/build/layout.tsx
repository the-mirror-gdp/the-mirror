import {
  ResizableHandle,
  ResizablePanel,
  ResizablePanelGroup,
} from "@/components/ui/resizable"
import { Link } from "lucide-react"
import { EnvVarWarning } from "@/components/env-var-warning"
import HeaderAuth from "@/components/header-auth"
import { appName } from "@/lib/copy-service"
import { hasEnvVars } from "@/utils/supabase/check-env-vars"
import { ThemeSwitcher } from "@/components/theme-switcher"

export default function ResizableDemo({ children }: any) {
  return (
    <>
      <nav className="w-full flex justify-center border-b border-b-foreground/10 h-16">
        <div className="w-full max-w-5xl flex justify-between items-center p-3 px-5 text-sm">
          <div className="flex gap-5 items-center font-semibold">
            <Link href={"/"}>{appName() || "The Mirror"}</Link>
          </div>
          {!hasEnvVars ? <EnvVarWarning /> : <HeaderAuth />}
        </div>
      </nav>
      <div className="h-dvh">
        <ResizablePanelGroup
          direction="horizontal"
          className="rounded-lg border h-auto"
          autoSave="true"
          autoSaveId={"mirrorBuildLayoutResizable"}
        >
          <ResizablePanel defaultSize={25}>
            <div className="flex h-full p-6">
              <span className="font-semibold">Sidebar</span>
            </div>
          </ResizablePanel>
          <ResizableHandle withHandle />
          <ResizablePanel defaultSize={75}>
            <div className="flex h-full items-center justify-center p-6">
              {children}
            </div>
          </ResizablePanel>
        </ResizablePanelGroup>
      </div>
      <footer className="w-full flex items-center justify-center border-t mx-auto text-center text-xs gap-8 py-16">
        <ThemeSwitcher />
      </footer>
    </>
  )
}

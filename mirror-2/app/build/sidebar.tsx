'use client';

import { Button } from "@/components/ui/button";
import { Tooltip, TooltipContent, TooltipProvider, TooltipTrigger } from "@/components/ui/tooltip";
import { atom, useAtom } from "jotai";
import { Box, Clapperboard, Code2, Database, GitBranch, Settings } from "lucide-react";

const sidebarCurrentViewAtom = atom("scene");

export function Sidebar() {
  const [currentView, setCurrentView] = useAtom(sidebarCurrentViewAtom);

  const handleViewChange = (view: string) => {
    setCurrentView(view);
  };

  const getVariant = (view: string) => {
    return currentView === view ? "default" : "ghost";
  };

  return (
    <TooltipProvider delayDuration={0}>
      <nav className="grid gap-2 p-2">
        <Tooltip>
          <TooltipTrigger asChild>
            <Button
              variant={getVariant("scene")}
              size="icon"
              aria-label="Scene"
              onClick={() => handleViewChange("scene")}
            >
              <Clapperboard className="size-7" />
            </Button>
          </TooltipTrigger>
          <TooltipContent side="right" sideOffset={5}>
            Scene
          </TooltipContent>
        </Tooltip>
        <Tooltip>
          <TooltipTrigger asChild>
            <Button
              variant={getVariant("assets")}
              size="icon"
              aria-label="Assets"
              onClick={() => handleViewChange("assets")}
            >
              <Box className="size-7" />
            </Button>
          </TooltipTrigger>
          <TooltipContent side="right" sideOffset={5}>
            Assets
          </TooltipContent>
        </Tooltip>
        <Tooltip>
          <TooltipTrigger asChild>
            <Button
              variant={getVariant("code")}
              size="icon"
              aria-label="Code"
              onClick={() => handleViewChange("code")}
            >
              <Code2 className="size-7" />
            </Button>
          </TooltipTrigger>
          <TooltipContent side="right" sideOffset={5}>
            Code
          </TooltipContent>
        </Tooltip>
        <Tooltip>
          <TooltipTrigger asChild>
            <Button
              variant={getVariant("database")}
              size="icon"
              aria-label="Database"
              onClick={() => handleViewChange("database")}
            >
              <Database className="size-7" />
            </Button>
          </TooltipTrigger>
          <TooltipContent side="right" sideOffset={5}>
            Database
          </TooltipContent>
        </Tooltip>
        <Tooltip>
          <TooltipTrigger asChild>
            <Button
              variant={getVariant("versions")}
              size="icon"
              aria-label="Versions"
              onClick={() => handleViewChange("versions")}
            >
              <GitBranch className="size-7" />
            </Button>
          </TooltipTrigger>
          <TooltipContent side="right" sideOffset={5}>
            Versions
          </TooltipContent>
        </Tooltip>
        <Tooltip>
          <TooltipTrigger asChild>
            <Button
              variant={getVariant("settings")}
              size="icon"
              aria-label="Settings"
              onClick={() => handleViewChange("settings")}
            >
              <Settings className="size-7" />
            </Button>
          </TooltipTrigger>
          <TooltipContent side="right" sideOffset={5}>
            Settings
          </TooltipContent>
        </Tooltip>
      </nav>
    </TooltipProvider>
  );
}

'use client';

import { controlBarCurrentViewAtom } from "@/app/space/[spaceId]/build/@controlBar/store";
import { Button } from "@/components/ui/button";
import { Tooltip, TooltipContent, TooltipProvider, TooltipTrigger } from "@/components/ui/tooltip";
import { uiSoundsCanPlayAtom, useUiHoverSoundEffect } from "@/components/ui/ui-sounds";
import { useAppDispatch, useAppSelector } from "@/hooks/hooks";
import { selectUiSoundsCanPlay, turnOffUiSounds, turnOnUiSounds } from "@/state/local";
import { atom, useAtom } from "jotai";
import { Box, Clapperboard, Code2, Database, GitBranch, Settings, Volume2, VolumeOff } from "lucide-react";


export default function ControlBar() {
  const [currentView, setCurrentView] = useAtom(controlBarCurrentViewAtom);
  const uiSoundsCanPlay = useAppSelector(selectUiSoundsCanPlay);
  const dispatch = useAppDispatch();
  const [play] = useUiHoverSoundEffect();

  const handleViewChange = (view: string) => {
    // play the sound ONLY if the view has changed
    if (currentView !== view) {
      play()
    }
    setCurrentView(view);
  };

  const getVariant = (view: string) => {
    return currentView === view ? "default" : "ghost";
  };

  return (
    <TooltipProvider delayDuration={750}>
      <nav className="flex flex-col gap-4 p-2 h-full">
        <div className="flex flex-col items-center cursor-pointer select-none" onClick={() => handleViewChange("scenes")} onMouseEnter={() => handleViewChange("scenes")}>
          <Tooltip>
            <TooltipTrigger asChild>
              <Button
                variant={getVariant("scenes")}
                size="icon"
                aria-label="Scenes"
                onClick={() => handleViewChange("scenes")}
              >
                <Clapperboard className="size-7" />
              </Button>
            </TooltipTrigger>
            <TooltipContent side="right" sideOffset={5}>
              Scenes
            </TooltipContent>
          </Tooltip>
          <span className="text-xs mt-1" >Scenes</span>
        </div>
        <div className="flex flex-col items-center cursor-pointer select-none" onClick={() => handleViewChange("assets")} onMouseEnter={() => handleViewChange("assets")}>
          <Tooltip>
            <TooltipTrigger asChild>
              <Button
                variant={getVariant("assets")}
                size="icon"
                aria-label="Assets"
                onClick={() => handleViewChange("assets")}
                onMouseEnter={() => handleViewChange("assets")}
              >
                <Box className="size-7" />
              </Button>
            </TooltipTrigger>
            <TooltipContent side="right" sideOffset={5}>
              Assets
            </TooltipContent>
          </Tooltip>
          <span className="text-xs mt-1" >Assets</span>
        </div>
        <div className="flex flex-col items-center cursor-pointer select-none" onClick={() => handleViewChange("code")} onMouseEnter={() => handleViewChange("code")}>
          <Tooltip>
            <TooltipTrigger asChild>
              <Button
                variant={getVariant("code")}
                size="icon"
                aria-label="Code"
                onClick={() => handleViewChange("code")}
                onMouseEnter={() => handleViewChange("code")}
              >
                <Code2 className="size-7" />
              </Button>
            </TooltipTrigger>
            <TooltipContent side="right" sideOffset={5}>
              Code
            </TooltipContent>
          </Tooltip>
          <span className="text-xs mt-1" >Code</span>
        </div>
        <div className="flex flex-col items-center cursor-pointer select-none" onClick={() => handleViewChange("database")} onMouseEnter={() => handleViewChange("database")}>
          <Tooltip>
            <TooltipTrigger asChild>
              <Button
                variant={getVariant("database")}
                size="icon"
                aria-label="Database"
                onClick={() => handleViewChange("database")}
                onMouseEnter={() => handleViewChange("database")}
              >
                <Database className="size-7" />
              </Button>
            </TooltipTrigger>
            <TooltipContent side="right" sideOffset={5}>
              Database
            </TooltipContent>
          </Tooltip>
          <span className="text-xs mt-1" >Database</span>
        </div>
        <div className="flex flex-col items-center cursor-pointer select-none" onClick={() => handleViewChange("versions")} onMouseEnter={() => handleViewChange("versions")}>
          <Tooltip>
            <TooltipTrigger asChild>
              <Button
                variant={getVariant("versions")}
                size="icon"
                aria-label="Versions"
                onClick={() => handleViewChange("versions")}
                onMouseEnter={() => handleViewChange("versions")}
              >
                <GitBranch className="size-7" />
              </Button>
            </TooltipTrigger>
            <TooltipContent side="right" sideOffset={5}>
              Versions
            </TooltipContent>
          </Tooltip>
          <span className="text-xs mt-1" >Versions</span>
        </div>
        <div className="flex flex-col items-center cursor-pointer select-none" onClick={() => handleViewChange("settings")} onMouseEnter={() => handleViewChange("settings")}>
          <Tooltip>
            <TooltipTrigger asChild>
              <Button
                variant={getVariant("settings")}
                size="icon"
                aria-label="Settings"
                onClick={() => handleViewChange("settings")}
                onMouseEnter={() => handleViewChange("settings")}
              >
                <Settings className="size-7" />
              </Button>
            </TooltipTrigger>
            <TooltipContent side="right" sideOffset={5}>
              Settings
            </TooltipContent>
          </Tooltip>
          <span className="text-xs mt-1" >Settings</span>
        </div>

        <div className="flex flex-col cursor-pointer select-none ml-2">
          <Tooltip>
            <TooltipTrigger asChild>
              <Button
                size="icon"
                aria-label="Toggle UI Sounds"
                onClick={() => {
                  dispatch(uiSoundsCanPlay ? turnOffUiSounds() : turnOnUiSounds());
                }}
                variant={"ghost"}
              >
                {uiSoundsCanPlay ? <Volume2 className="size-7 text-gray-400" /> : <VolumeOff className="size-7 text-gray-500" />}
              </Button>
            </TooltipTrigger>
            <TooltipContent side="right" sideOffset={5}>
              Toggle UI Sounds
            </TooltipContent>
          </Tooltip>
        </div>
      </nav>
    </TooltipProvider>
  );
}

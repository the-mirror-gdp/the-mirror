"use client"
import Scenes from "@/app/space/[spaceId]/build/@controlBar/scenes";
import Assets from "@/app/space/[spaceId]/build/@controlBar/assets";
import { controlBarCurrentViewAtom } from "./store";
import { useAtom } from "jotai";

export default function InnerControlBar() {
  const [currentView, setCurrentView] = useAtom(controlBarCurrentViewAtom);

  return (
    <div>
      {currentView === "assets" && <Assets />}
      {currentView === "scenes" && <Scenes />}
    </div>
  );
}

"use client"
import Assets from "@/app/space/[spaceId]/build/@controlBar/assets";
import Code from "@/app/space/[spaceId]/build/@controlBar/code";
import Database from "@/app/space/[spaceId]/build/@controlBar/database";
import Hierarchy from "@/app/space/[spaceId]/build/@controlBar/hierarchy";
import Scenes from "@/app/space/[spaceId]/build/@controlBar/scenes";
import Settings from "@/app/space/[spaceId]/build/@controlBar/settings";
import { SkeletonCard } from "@/app/space/[spaceId]/build/@controlBar/skeleton-card";
import Versions from "@/app/space/[spaceId]/build/@controlBar/versions";
import { useAppSelector } from "@/hooks/hooks";
import { selectControlBarCurrentView } from "@/state/local";
import { Suspense } from "react";

export default function InnerControlBar() {
  const currentView = useAppSelector(selectControlBarCurrentView);

  return (
    <div>
      <Suspense fallback={SkeletonCard()}>
        {currentView === "scenes" && <Scenes />}
        {currentView === "hierarchy" && <Hierarchy />}
        {currentView === "assets" && <Assets />}
        {currentView === "code" && <Code />}
        {currentView === "database" && <Database />}
        {currentView === "versions" && <Versions />}
        {currentView === "settings" && <Settings />}
      </Suspense>

    </div >
  );
}

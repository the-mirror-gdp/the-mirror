"use client"
import Assets from "@/app/space/[spaceId]/build/(controlBar)/assets";
import Code from "@/app/space/[spaceId]/build/(controlBar)/code";
import Database from "@/app/space/[spaceId]/build/(controlBar)/database";
import Hierarchy from "@/app/space/[spaceId]/build/(controlBar)/hierarchy";
import Scenes from "@/app/space/[spaceId]/build/(controlBar)/scenes";
import Settings from "@/app/space/[spaceId]/build/(controlBar)/settings";
import { SkeletonCard } from "@/app/space/[spaceId]/build/(controlBar)/skeleton-card";
import Versions from "@/app/space/[spaceId]/build/(controlBar)/versions";
import { useAppSelector } from "@/hooks/hooks";
import { selectControlBarCurrentView } from "@/state/local";
import { Suspense } from "react";

export default function InnerControlBar() {
  const currentView = useAppSelector(selectControlBarCurrentView);

  return (
    <div className="p-2 m-2">
      <Suspense fallback={SkeletonCard()}>
        <span className={`${currentView === "scenes" ? "" : "hidden"}`}><Scenes /></span>
        <span className={`${currentView === "hierarchy" ? "" : "hidden"}`}><Hierarchy /></span>
        <span className={`${currentView === "assets" ? "" : "hidden"}`}><Assets /></span>
        <span className={`${currentView === "code" ? "" : "hidden"}`}><Code /></span>
        <span className={`${currentView === "database" ? "" : "hidden"}`}><Database /></span>
        <span className={`${currentView === "versions" ? "" : "hidden"}`}><Versions /></span>
        <span className={`${currentView === "settings" ? "" : "hidden"}`}><Settings /></span>
      </Suspense>

    </div >
  );
}

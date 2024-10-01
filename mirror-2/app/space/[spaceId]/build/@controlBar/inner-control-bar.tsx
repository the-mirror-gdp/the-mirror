"use client"
import Assets from "@/app/space/[spaceId]/build/@controlBar/assets";
import Code from "@/app/space/[spaceId]/build/@controlBar/code";
import Scenes from "@/app/space/[spaceId]/build/@controlBar/scenes";
import { SkeletonCard } from "@/app/space/[spaceId]/build/@controlBar/skeleton-card";
import { useAppSelector } from "@/hooks/hooks";
import { selectControlBarCurrentView } from "@/state/local";
import { Suspense } from "react";

export default function InnerControlBar() {
  const currentView = useAppSelector(selectControlBarCurrentView);

  return (
    <div>
      <Suspense fallback={SkeletonCard()}>
        Test Inner
        {currentView === "assets" && <Assets />}
        {currentView === "scenes" && <Scenes />}
        {currentView === "code" && <Code />}
      </Suspense>

    </div >
  );
}

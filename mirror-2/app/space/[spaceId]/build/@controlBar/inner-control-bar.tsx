"use client"
import Scenes from "@/app/space/[spaceId]/build/@controlBar/scenes";
import Assets from "@/app/space/[spaceId]/build/@controlBar/assets";
import { controlBarCurrentViewAtom } from "./store";
import { useAtom } from "jotai";
import { Suspense } from "react";
import Code from "@/app/space/[spaceId]/build/@controlBar/code";
import { SkeletonCard } from "@/app/space/[spaceId]/build/@controlBar/skeleton-card";

export default function InnerControlBar() {
  const [currentView] = useAtom(controlBarCurrentViewAtom);

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

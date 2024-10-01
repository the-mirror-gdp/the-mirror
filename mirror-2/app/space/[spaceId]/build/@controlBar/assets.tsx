'use client';
import ControlBar from "@/app/space/[spaceId]/build/@controlBar/control-bar";
import { asyncTimeoutAtom } from "@/app/space/[spaceId]/build/@controlBar/store";
import { useAtom } from "jotai";
import { Suspense } from "react";

export default function Assets() {
  const [test] = useAtom(asyncTimeoutAtom);
  return (
    <div>Assets: {test}</div>
  );
}

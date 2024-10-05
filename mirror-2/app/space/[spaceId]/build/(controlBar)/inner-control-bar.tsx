'use client';

import Assets from "@/app/space/[spaceId]/build/(controlBar)/assets";
import Code from "@/app/space/[spaceId]/build/(controlBar)/code";
import Database from "@/app/space/[spaceId]/build/(controlBar)/database";
import Hierarchy from "@/app/space/[spaceId]/build/(controlBar)/hierarchy";
import Scenes from "@/app/space/[spaceId]/build/(controlBar)/scenes";
import Settings from "@/app/space/[spaceId]/build/(controlBar)/settings";
import { SkeletonCard } from "@/app/space/[spaceId]/build/(controlBar)/skeleton-card";
import Versions from "@/app/space/[spaceId]/build/(controlBar)/versions";
import { useGetFileUpload } from "@/hooks/file-upload";
import { useAppSelector } from "@/hooks/hooks";
import { selectControlBarCurrentView } from "@/state/local";
import { Suspense } from "react";
import { useDropzone } from "react-dropzone";

export default function InnerControlBar() {
  const currentView = useAppSelector(selectControlBarCurrentView);

  // File dropzone
  const onDrop = useGetFileUpload();

  const { getRootProps, getInputProps, isDragActive } = useDropzone({
    noClick: true,
    noKeyboard: true,
    onDrop,
  });

  return (
    <div className="relative p-2 m-2" {...getRootProps()}>
      {/* Input element for handling file uploads */}
      <input {...getInputProps()} />

      {/* Overlay that is shown when a file is dragged over the area */}
      <div
        className={`absolute inset-0 bg-gradient-to-b from-black via-primary to-black bg-opacity-30 ${isDragActive ? 'opacity-80 visible' : 'opacity-0 invisible'
          } transition-opacity duration-300 ease-in-out flex justify-center items-center z-10`}
      >
        <p className="text-white font-semibold text-lg mt-5">Drop your file here</p>
      </div>

      {/* Content of the control bar */}
      <Suspense fallback={<SkeletonCard />}>
        <span className={`${currentView === "scenes" ? "" : "hidden"}`}><Scenes /></span>
        <span className={`${currentView === "hierarchy" ? "" : "hidden"}`}><Hierarchy /></span>
        <span className={`${currentView === "assets" ? "" : "hidden"}`}><Assets /></span>
        <span className={`${currentView === "code" ? "" : "hidden"}`}><Code /></span>
        <span className={`${currentView === "database" ? "" : "hidden"}`}><Database /></span>
        <span className={`${currentView === "versions" ? "" : "hidden"}`}><Versions /></span>
        <span className={`${currentView === "settings" ? "" : "hidden"}`}><Settings /></span>
      </Suspense>
    </div>
  );
}

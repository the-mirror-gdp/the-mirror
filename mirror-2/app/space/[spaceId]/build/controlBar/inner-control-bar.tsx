'use client';

import Assets from "@/app/space/[spaceId]/build/controlBar/assets";
import Code from "@/app/space/[spaceId]/build/controlBar/code";
import Database from "@/app/space/[spaceId]/build/controlBar/database";
import Hierarchy from "@/app/space/[spaceId]/build/controlBar/hierarchy";
import Scenes from "@/app/space/[spaceId]/build/controlBar/scenes";
import Settings from "@/app/space/[spaceId]/build/controlBar/settings";
import { SkeletonCard } from "@/app/space/[spaceId]/build/controlBar/skeleton-card";
import Versions from "@/app/space/[spaceId]/build/controlBar/versions";
import { useGetFileUpload } from "@/hooks/file-upload";
import { useAppSelector } from "@/hooks/hooks";
import { selectControlBarCurrentView } from "@/state/local.slice";
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
    <div className="relative px-2 h-full overflow-y-auto" {...getRootProps()}>
      {/* Input element for handling file uploads */}
      <input {...getInputProps()} />

      {/* Overlay that is shown when a file is dragged over the area */}
      <div
        className={`absolute inset-0 bg-gradient-to-b from-black via-primary to-black bg-opacity-30 ${isDragActive ? 'opacity-80 visible' : 'opacity-0 invisible'
          } transition-opacity duration-300 ease-in-out flex justify-center items-center z-10`}
      >
        <p className="text-white font-semibold text-lg mt-5">Drop Your Asset Here</p>
      </div>

      {/* Content of the control bar */}
      <Suspense fallback={<SkeletonCard />}>
        <div className="flex flex-col pt-3">
          {currentView === "scenes" && <Scenes />}
          {currentView === "hierarchy" && <Hierarchy />}
          {currentView === "assets" && <Assets />}
          {currentView === "code" && <Code />}
          {currentView === "database" && <Database />}
          {currentView === "versions" && <Versions />}
          {currentView === "settings" && <Settings />}
        </div>
      </Suspense>
    </div>
  );
}

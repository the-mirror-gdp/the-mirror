import React from "react";
import { Separator } from "@/components/ui/separator";
import { Metadata } from "next";
import { Sidebar } from "@/app/home/components/sidebar";
import { playlists } from "@/app/home/data/playlists";

export const metadata: Metadata = {
  title: "Discover",
  description: "",
};
const MyAccount = () => {
  return (
    <div className="bg-background flex">
      <Sidebar
        playlists={playlists}
        className="hidden lg:block w "
        style={{
          width: "25%",
        }}
      />
      <div
        className="py-6 px-6 w-full"
        style={{
          maxWidth: "50%",
        }}
      >
        <div className="flex items-center justify-between">
          <div className="space-y-1">
            <h2 className="text-3xl font-semibold tracking-tight">
              Account Settings
            </h2>
          </div>
        </div>
        <Separator className="my-4" />
        <div className="flex items-center gap-2 mobile:gap-1 w-full justify-between">
          <div className="flex relative">
            <div className="flex-wrap mt-1 rounded-md shadow-sm">
              <input
                id="email"
                autoComplete="none"
                name="email"
                type="email"
                placeholder="tarun@themirror.space"
                className="block h-[3.125rem] rounded-xl focus:outline-none pt-6 pl-4 bg-bluenav text-white text-base font-semibold font-primary border-gray-700 text-disabledMirror focus:border-ringBlue border-none bg-transparent"
                value="tarun@themirror.space"
              />
              <label
                htmlFor="email"
                className="absolute left-4 top-2 text-textInput text-xs font-semibold font-primary peer-placeholder-shown:text-sm peer-focus:text-xs"
              >
                Email
              </label>
            </div>
          </div>
          <button
            type="button"
            className="flex justify-center max-h-[3.125rem] items-center whitespace-nowrap p-3 bg-blueMirror rounded-xl font-primary font-semibold border border-transparent text-white shadow-[0_2px_40px_0px_rgba(57,121,255,0.4)]  min-w-fit mobile:text-xs bg-transparent shadowNone text-blueMirror bg-[#121428]
      hover:bg-blue-700 hover:ease-in duration-100 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-400"
          >
            <svg
              xmlns="http://www.w3.org/2000/svg"
              viewBox="0 0 20 20"
              fill="currentColor"
              aria-hidden="true"
              className="w-6 h-6"
            >
              <path d="M13.586 3.586a2 2 0 112.828 2.828l-.793.793-2.828-2.828.793-.793zM11.379 5.793L3 14.172V17h2.828l8.38-8.379-2.83-2.828z"></path>
            </svg>{" "}
          </button>
        </div>
      </div>
    </div>
  );
};

export default MyAccount;

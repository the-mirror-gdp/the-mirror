import React, { MouseEventHandler } from "react";

const EditButton = () => {
  return (
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
  );
};

export default EditButton;

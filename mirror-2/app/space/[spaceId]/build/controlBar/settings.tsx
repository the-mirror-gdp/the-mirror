'use client';

import { Button } from "@/components/ui/button";
import { FileUp, FolderInput } from "lucide-react";
import { useRef } from "react";

// Assuming modifyFile is an API endpoint that handles the file modification
const modifyFile = async (file: File) => {
  const formData = new FormData();
  formData.append('file', file);

  // Call your API to modify the file
  const response = await fetch('/api/modify-file', {
    method: 'POST',
    body: formData,
  });

  const result = await response.json();
  return result;
};

export default function Settings() {
  const fileInputRef = useRef<HTMLInputElement | null>(null);

  const handleFileUpload = async (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (file) {
      try {
        const result = await modifyFile(file);
        console.log(result);  // Handle success or error response
      } catch (error) {
        console.error("Error uploading and modifying file:", error);
      }
    }
  };

  const openFileDialog = () => {
    if (fileInputRef.current) {
      fileInputRef.current.click();  // Open the file dialog
    }
  };

  return (
    <>
      <input
        type="file"
        ref={fileInputRef}
        onChange={handleFileUpload}
        style={{ display: 'none' }}  // Hide the file input
      />
      <Button className="w-full mb-4 mt-2" type="button" onClick={openFileDialog}>
        <FolderInput className="size-7 mr-2" />
        Import PlayCanvas App
      </Button>
      <p>To import an existing app from PlayCanvas, export it as a .zip.  </p>
      <p className="mt-1">The export must have:</p>
      <ul>
        <li>Engine Version: >=1.74.0</li>
        <li>Concatenate Scripts: Unchecked</li>
        <li>Optimize Scene Format: Unchecked</li>
        <li>Format: .zip</li>
      </ul>


    </>
  );
}

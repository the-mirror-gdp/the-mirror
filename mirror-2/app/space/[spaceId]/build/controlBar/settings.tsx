'use client';

import { useRef } from 'react';
import { Button } from '@/components/ui/button';
import { FolderInput } from 'lucide-react';
import { usePCZipFileUpload } from '@/utils/pc-import';


export default function Settings() {
  const fileInputRef = useRef<HTMLInputElement | null>(null);
  const { uploading, handlePCZipFileUpload } = usePCZipFileUpload(); // Use the hook

  const handleFileInputChange = async (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (file) {
      await handlePCZipFileUpload(file); // Call the hook function
    }
  };

  const openFileDialog = () => {
    if (fileInputRef.current) {
      fileInputRef.current.click(); // Open the file dialog
    }
  };

  return (
    <>
      <input
        type="file"
        ref={fileInputRef}
        onChange={handleFileInputChange} // Trigger when file is selected
        name="pc-app-import"
        accept=".zip"
        style={{ display: 'none' }} // Hide the file input button
      />
      <Button className="w-full mb-4 mt-2" type="button" onClick={openFileDialog} disabled={uploading}>
        <FolderInput className="size-7 mr-2" />
        {uploading ? 'Uploading...' : 'Import from PlayCanvas'}
      </Button>
      <div>
        <p>To import an existing app from PlayCanvas, export it as a .zip.</p>
        <p className="mt-1">The export must have:</p>
        <ul>
          <li>Engine Version: {'>=1.74.0'}</li>
          <li>Concatenate Scripts: Unchecked</li>
          <li>Optimize Scene Format: Unchecked</li>
          <li>Format: .zip</li>
        </ul>
      </div>
    </>
  );
}

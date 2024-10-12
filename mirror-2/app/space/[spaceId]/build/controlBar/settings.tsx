'use client';

import { useRef, useState } from 'react';
import { Button } from '@/components/ui/button';
import { FolderInput } from 'lucide-react';

export default function Settings() {
  const fileInputRef = useRef<HTMLInputElement | null>(null);
  const [uploading, setUploading] = useState(false);

  const handleFileUpload = async (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (file) {
      try {
        setUploading(true);

        // Create FormData and append the file
        const formData = new FormData();
        formData.append('file', file);
        console.log('startc')
        // Send the file to the API route in the app router
        const response = await fetch('/api/upload', {
          method: 'POST',
          body: formData,
        });

        const result = await response.json();
        console.log(result);
        setUploading(false);
      } catch (error) {
        console.error('Error uploading and modifying file:', error);
        setUploading(false);
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
        name="pc-app-import"
        style={{ display: 'none' }}  // Hide the file input
      />
      <Button className="w-full mb-4 mt-2" type="button" onClick={openFileDialog} disabled={uploading}>
        <FolderInput className="size-7 mr-2" />
        {uploading ? 'Uploading...' : 'Import from PlayCanvas'}
      </Button>
      <div>
        <p>To import an existing app from PlayCanvas, export it as a .zip.</p>
        <p className="mt-1">The export must have:</p>
        <ul>
          <li>Engine Version: >=1.74.0</li>
          <li>Concatenate Scripts: Unchecked</li>
          <li>Optimize Scene Format: Unchecked</li>
          <li>Format: .zip</li>
        </ul>
      </div>
    </>
  );
}

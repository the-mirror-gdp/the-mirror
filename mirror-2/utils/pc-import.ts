"use client"
import JSZip from 'jszip';
import { useState } from 'react';
import { createSupabaseBrowserClient } from '@/utils/supabase/client';
import {snakeCase} from 'change-case'
import { useCreatePcImportMutation } from '@/state/pc-imports';
import { useAppSelector } from '@/hooks/hooks';
import { selectLocalUser } from '@/state/local';

// Create the Supabase client
const supabase = createSupabaseBrowserClient();


export const usePCZipFileUpload = () => {
  const [uploading, setUploading] = useState(false); // State to manage the upload progress
  const [createPcImport, { data: createdPcImport }] = useCreatePcImportMutation(); // Mutation for creating pcImport
  const localUser = useAppSelector(selectLocalUser)

  const handlePCZipFileUpload = async (file: File) => {
    try {
      if (!localUser) {
        throw new Error("User not logged in")
      }

      setUploading(true);

      // Step 1: Create a pcImport in the database
      const pcImportData = await createPcImport({ displayName: file.name }).unwrap();

      if (!pcImportData?.id) {
        throw new Error('Failed to retrieve pcImport ID');
      }

      const pcImportId = pcImportData.id; // Get the newly created pcImport ID



      // Step 2: Read the file as an ArrayBuffer
      const arrayBuffer = await file.arrayBuffer();

      // Step 3: Proceed with unzipping and processing the file using the pcImportId
      // await processZipFile(arrayBuffer, pcImportId, assetPrefix, scriptPrefix);
      const zip = await JSZip.loadAsync(arrayBuffer);

      // Modify the files in the ZIP
      // await modifyZipFiles(zip, assetPrefix, scriptPrefix);
    
      // Upload the files to Supabase Storage
      await uploadZipToSupabase(zip, pcImportId);

      setUploading(false);
    } catch (error) {
      console.error('Error uploading and modifying file:', error);
      setUploading(false);
    }
  };

  return { uploading, handlePCZipFileUpload };
};


// Function to modify files 
export const modifySettingsFileFromSupabase = async (settingsFileUrl: string, assetPrefix: string, scriptPrefix: string, configFilenameUrl: string) => {
  try {
    // Fetch the settings file from the Supabase public URL
    const response = await fetch(settingsFileUrl);
    
    if (!response.ok) {
      throw new Error(`Failed to fetch settings file from Supabase: ${response.statusText}`);
    }

    const content = await response.text();

    // Perform replacements
    const modifiedContent = content
      .replace(/window\.ASSET_PREFIX\s*=\s*".*?"/g, `window.ASSET_PREFIX = "${assetPrefix}"`)
      .replace(/window\.SCRIPT_PREFIX\s*=\s*".*?"/g, `window.SCRIPT_PREFIX = "${scriptPrefix}"`)
      .replace(/window\.SCENE_PATH\s*=\s*"(?:.*\/)?(\d+\.json)"/g, 'window.SCENE_PATH = "$1"')
      .replace(/'powerPreference'\s*:\s*".*?"/g, '\'powerPreference\': "high-performance"')
      .replace(/window\.CONFIG_FILENAME\s*=\s*".*?"/g, `window.CONFIG_FILENAME = "${configFilenameUrl}"`);

    // Use or return the modified content (you can upload it back to Supabase or serve it as needed)
    console.log('Modified content:', modifiedContent);

    // If you need to save the modified file back to Supabase or another location, you can use the appropriate API.
    return modifiedContent;
    
  } catch (error) {
    console.error('Error modifying settings file:', error);
    throw error;
  }
};


// Function to upload files to Supabase Storage
const uploadZipToSupabase = async (zip: JSZip, pcImportId: string) => {
  // Get the authenticated user
  const { data: { user } } = await supabase.auth.getUser();

  if (!user) {
    throw new Error('User not authenticated');
  }

  // Generate a list of files to upload
  const files: any[] = [];
  zip.forEach((relativePath, file) => {
    files.push({ relativePath, file });
  });

  // Upload each file to Supabase Storage
  for (const { relativePath, file } of files) {
    if (!file.dir) {
      const fileData = await file.async('blob');
      const path = `${user.id}/${pcImportId}/${relativePath}`
      const { error } = await supabase.storage
        .from('pc-imports')
        .upload(path, fileData, {
          upsert: true,
        });

      if (error) {
        console.error(`Failed to upload ${relativePath}:`, error);
        throw new Error(error.message);
      }
    }
  }
};

export function getASSET_PREFIXForLoadingEngineApp(userId: string, pcImportId: string) {
return `${userId}/${pcImportId}`
}

export function getSCRIPT_PREFIXForLoadingEngineApp(userId: string, pcImportId: string) {
return `${userId}/${pcImportId}/`
}

export function getBrowserScriptTagUrlForLoadingScriptsFromStorage(userId: string, pcImportId: string) {
  return `/${userId}/${pcImportId}`
  }

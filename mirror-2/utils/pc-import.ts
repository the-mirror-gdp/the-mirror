import JSZip from 'jszip';
import { createSupabaseBrowserClient } from '@/utils/supabase/client';

// Create the Supabase client
const supabase = createSupabaseBrowserClient();

// Function to handle the file upload
export const handlePCZipFileUpload = async (file: File, setUploading: (state: boolean) => void) => {
  const fileName = file.name; // Get the name of the file

  try {
    setUploading(true);

    // Read the file as an ArrayBuffer
    const arrayBuffer = await file.arrayBuffer();

    // Proceed with unzipping and processing the file
    await processZipFile(arrayBuffer, fileName);

    setUploading(false);
  } catch (error) {
    console.error('Error uploading and modifying file:', error);
    setUploading(false);
  }
};

// Function to process the ZIP file
const processZipFile = async (arrayBuffer: ArrayBuffer, fileName: string) => {
  const zip = await JSZip.loadAsync(arrayBuffer);

  // Modify the files in the ZIP
  await modifyZipFiles(zip);

  // Upload the files to Supabase Storage
  await uploadZipToSupabase(zip, fileName);
};

// Function to modify files within the ZIP
const modifyZipFiles = async (zip: JSZip) => {
  // Find and modify __settings__.import.js
  const settingsFilePath = '__settings__.js';
  const settingsFile = zip.file(settingsFilePath);

  if (settingsFile) {
    const content = await settingsFile.async('string');

    // Perform replacements
    const modifiedContent = content
      .replace(/window\.ASSET_PREFIX\s*=\s*".*?"/g, 'window.ASSET_PREFIX = "../../sample/"')
      .replace(/window\.SCRIPT_PREFIX\s*=\s*".*?"/g, 'window.SCRIPT_PREFIX = "../../sample"')
      .replace(/window\.SCENE_PATH\s*=\s*"(?:.*\/)?(\d+\.json)"/g, 'window.SCENE_PATH = "../../sample/$1"')
      .replace(/'powerPreference'\s*:\s*".*?"/g, '\'powerPreference\': "high-performance"');

    // Update the file in the ZIP
    zip.file(settingsFilePath, modifiedContent);
  } else {
    console.error('Settings file not found in the uploaded zip');
    throw new Error('Settings file not found in the uploaded zip');
  }
};

// Function to upload files to Supabase Storage
const uploadZipToSupabase = async (zip: JSZip, fileName: string) => {
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

      const { error } = await supabase.storage
        .from('pc-imports')
        .upload(`${user.id}/${fileName}/${relativePath}`, fileData, {
          upsert: true,
        });

      if (error) {
        console.error(`Failed to upload ${relativePath}:`, error);
        throw new Error(error.message);
      }
    }
  }
};

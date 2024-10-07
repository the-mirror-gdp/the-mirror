import { useCallback } from "react";

import { Database } from "@/utils/database.types";
import { useCreateAssetMutation } from "@/state/assets";


export function useGetFileUpload() {
  // Get the mutation hook
  const [createAsset] = useCreateAssetMutation();

  return useCallback((acceptedFiles: File[]) => {
    acceptedFiles.forEach((file) => {
      // Create the asset record for each file uploaded
      const assetData = {
        name: file.name, // Use the file name as the asset name
        // description: 'Auto-generated description', // TODO add description support
      };

      createAsset({
        assetData, // Asset data with name and description
        file,      // File to upload
      })
        .unwrap() // Unwraps the result to handle promise resolution
        .then((response) => {
          console.log('File uploaded and asset created successfully:', response);
        })
        .catch((error) => {
          console.error('Error uploading file or creating asset:', error);
        });
    });
  }, [createAsset]);
}

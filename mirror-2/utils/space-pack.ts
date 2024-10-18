'use client'
import JSZip from 'jszip'
import { useState } from 'react'
import { createSupabaseBrowserClient } from '@/utils/supabase/client'
import { snakeCase } from 'change-case'
import { useAppSelector } from '@/hooks/hooks'
import { selectLocalUser } from '@/state/local.slice'
import {
  SPACE_PACKS_BUCKET_NAME,
  useCreateSpacePackMutation
} from '@/state/api/space-packs'

/**
 * Important: When we importing an app, it's stored in an IMMUTABLE form intentionally; with different engine versions and settings, we'll need to patch our __start-custom__.js to handle different cases depending on what the importing app was built on. We don't want to modify the imported files; that's done at runtime for future compatability and not having to run migrations.
 * Further, we can still optimize this with running the imports server-side with NextJS, but not a priority right now since it's fast.
 */

// Create the Supabase client
const supabase = createSupabaseBrowserClient()

export const useSpacePackZipFileUpload = (spaceId: number) => {
  const [uploading, setUploading] = useState(false) // State to manage the upload progress
  const [createSpacePack, { data: createdSpacePack }] =
    useCreateSpacePackMutation() // Mutation for creating spacePack
  const localUser = useAppSelector(selectLocalUser)

  const handleSpacePackZipFileUpload = async (file: File) => {
    try {
      if (!localUser) {
        throw new Error('User not logged in')
      }

      setUploading(true)

      // Step 1: Create a spacePack in the database
      const spacePackData = await createSpacePack({
        display_name: file.name,
        data: {},
        space_id: spaceId
      }).unwrap()

      if (!spacePackData?.id) {
        throw new Error('Failed to retrieve spacePack ID')
      }

      const spacePackId = spacePackData.id // Get the newly created spacePack ID

      // Step 2: Read the file as an ArrayBuffer
      const arrayBuffer = await file.arrayBuffer()

      // Step 3: Proceed with unzipping and processing the file using the spacePackId
      // await processZipFile(arrayBuffer, spacePackId, assetPrefix, scriptPrefix);
      const zip = await JSZip.loadAsync(arrayBuffer)

      // Modify the files in the ZIP
      // await modifyZipFiles(zip, assetPrefix, scriptPrefix);

      // Upload the files to Supabase Storage
      await uploadZipToSupabase(zip, spacePackId)

      setUploading(false)
    } catch (error) {
      console.error('Error uploading and modifying file:', error)
      setUploading(false)
    }
  }

  return { uploading, handlePCZipFileUpload: handleSpacePackZipFileUpload }
}

// Function to modify files
export const modifySettingsFileFromSupabase = async (
  settingsFileUrl: string,
  assetPrefix: string,
  scriptPrefix: string,
  configFilenameUrl: string
) => {
  try {
    // Fetch the settings file from the Supabase public URL
    const response = await fetch(settingsFileUrl)

    if (!response.ok) {
      throw new Error(
        `Failed to fetch settings file from Supabase: ${response.statusText}`
      )
    }

    const content = await response.text()

    // Perform replacements
    const modifiedContent = content
      .replace(
        /window\.ASSET_PREFIX\s*=\s*".*?"/g,
        `window.ASSET_PREFIX = "${assetPrefix}"`
      )
      .replace(
        /window\.SCRIPT_PREFIX\s*=\s*".*?"/g,
        `window.SCRIPT_PREFIX = "${scriptPrefix}"`
      )
      .replace(
        /window\.SCENE_PATH\s*=\s*"(?:.*\/)?(\d+\.json)"/g,
        'window.SCENE_PATH = "$1"'
      )
      .replace(
        /'powerPreference'\s*:\s*".*?"/g,
        '\'powerPreference\': "high-performance"'
      )
      .replace(
        /window\.CONFIG_FILENAME\s*=\s*".*?"/g,
        `window.CONFIG_FILENAME = "${configFilenameUrl}"`
      )

    // Use or return the modified content (you can upload it back to Supabase or serve it as needed)
    console.log('Modified content:', modifiedContent)

    // If you need to save the modified file back to Supabase or another location, you can use the appropriate API.
    return modifiedContent
  } catch (error) {
    console.error('Error modifying settings file:', error)
    throw error
  }
}

// Function to upload files to Supabase Storage
const uploadZipToSupabase = async (zip: JSZip, spacePackId: number) => {
  // Get the authenticated user
  const {
    data: { user }
  } = await supabase.auth.getUser()

  if (!user) {
    throw new Error('User not authenticated')
  }

  // Generate a list of files to upload
  const files: any[] = []
  zip.forEach((relativePath, file) => {
    files.push({ relativePath, file })
  })

  // Upload each file to Supabase Storage
  for (const { relativePath, file } of files) {
    if (!file.dir) {
      const fileData = await file.async('blob')
      const path = `${user.id}/${spacePackId}/${relativePath}`
      const { error } = await supabase.storage
        .from(SPACE_PACKS_BUCKET_NAME)
        .upload(path, fileData, {
          upsert: true
        })

      if (error) {
        console.error(`Failed to upload ${relativePath}:`, error)
        throw new Error(error.message)
      }
    }
  }
}

export function getASSET_PREFIXForLoadingEngineApp(
  userId: string,
  spacePackId: string
) {
  return `${userId}/${spacePackId}`
}

export function getSCRIPT_PREFIXForLoadingEngineApp(
  userId: string,
  spacePackId: string
) {
  return `${userId}/${spacePackId}/`
}

export function getBrowserScriptTagUrlForLoadingScriptsFromStorage(
  userId: string,
  spacePackId: string
) {
  return `/${userId}/${spacePackId}`
}

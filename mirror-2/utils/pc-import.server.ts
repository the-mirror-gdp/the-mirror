"use server";

import { replaceInFile } from 'replace-in-file';
import path from 'path';
import { promises as fs } from 'fs';  // Use promises from fs to check file existence
import { pipeline } from 'stream';
import { promisify } from 'util';
import unzipper from 'unzipper';
import { Readable } from 'stream/web';  // Import Readable from 'stream/web'

const pipelineAsync = promisify(pipeline);

export async function pcImport(file: File) {
  // Step 1: Unzip the file
  const unzippedFolderPath = await unzipFile(file);

  // Step 2: Find the location of __settings__.import.js within the unzipped directory
  const settingsFilePath = await findSettingsFile(unzippedFolderPath, '__settings__.import.js');

  // Step 3: Pass the located file to modifyFiles
  if (settingsFilePath) {
    return await modifyFiles(settingsFilePath);
  } else {
    throw new Error('Unable to locate __settings__.import.js in the unzipped directory.');
  }
}

// async function unzipFile(file: File): Promise<string> {
//   const outputDir = path.join(process.cwd(), 'temp/unzipped');  // Define the output folder
//   await fs.mkdir(outputDir, { recursive: true });

//   // Convert Web API ReadableStream (file.stream()) to Node.js Readable stream
//   const nodeReadableStream = Readable.fromWeb(file.stream());

//   // Use pipeline to pipe the stream to the unzipper
//   await pipelineAsync(
//     nodeReadableStream,
//     unzipper.Extract({ path: outputDir })  // Extract files to the specified folder
//   );

//   return outputDir;  // Return the path to the unzipped directory
// }

async function findSettingsFile(dir: string, filename: string): Promise<string | null> {
  const files = await fs.readdir(dir, { withFileTypes: true });

  for (const file of files) {
    const filePath = path.join(dir, file.name);

    if (file.isDirectory()) {
      // Recursively search directories
      const result = await findSettingsFile(filePath, filename);
      if (result) return result;
    } else if (file.name === filename) {
      return filePath;  // Return the path if the file is found
    }
  }

  return null;  // Return null if the file isn't found
}

async function modifyFiles(filePath: string) {
  try {
    const settingsResult = await modifySettings(filePath);

    // Return the results or message
    if (settingsResult.length > 0 && settingsResult[0].hasChanged) {
      return "File modified successfully!";
    } else {
      return "No changes made.";
    }
  } catch (error) {
    console.error('Error modifying file:', error);
    throw new Error('Failed to modify the file.');
  }
}

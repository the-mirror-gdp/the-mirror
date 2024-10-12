"use server";

import { replaceInFile } from 'replace-in-file';
import path from 'path';
import { promises as fs } from 'fs';  // Use promises from fs to check file existence

export async function modifyFile() {
  try {

    const settingsResult = await modifySettings()
    // const startResult = await modifyStart()

    // Return the results or message
    if (settingsResult.length > 0 && settingsResult[0].hasChanged) {
      return "File modified successfully!";
    } else {
      return "No changes made.";
    }
  } catch (error) {
    // If the file cannot be accessed, or there was an error
    console.error('Error modifying file:', error);
    throw new Error('Failed to modify the file.');
  }
}

 async function modifySettings() {
      // __settings__.js
      const filePath = path.join(process.cwd(), 'public/sample/__settings__.import.js');

      // Check if the file exists and is accessible
      await fs.access(filePath);
  
      // Set up replace-in-file options
      const options = {
        files: filePath,
        from: [
          /window\.ASSET_PREFIX\s*=\s*".*?"/g,  // Matches any ASSET_PREFIX assignment
          /window\.SCRIPT_PREFIX\s*=\s*".*?"/g,  // Matches any SCRIPT_PREFIX assignment
          /window\.SCENE_PATH\s*=\s*"(?:.*\/)?(\d+\.json)"/g,  // Captures SCENE_PATH's number.json
          /'powerPreference'\s*:\s*".*?"/g  // Matches powerPreference's value
        ],
        to: [
          'window.ASSET_PREFIX = "../../sample/"',      // Replacement for ASSET_PREFIX
          'window.SCRIPT_PREFIX = "../../sample"',     // Replacement for SCRIPT_PREFIX
          'window.SCENE_PATH = "../../sample/$1"',     // Prefix SCENE_PATH with "../../sample/"
          '\'powerPreference\': "high-performance"'    // Replaces any powerPreference value with "high-performance"
        ],
      };
  
      // Perform the replacement
   const results = await replaceInFile(options);
  return results
}

// export async function modifyStart() {
//   // Path to __start__.import.js
//   const filePath = path.join(process.cwd(), 'public/sample/__start__.import.js');

//   // Check if the file exists and is accessible
//   await fs.access(filePath);

//   // Set up replace-in-file options
//   const options = {
//     files: filePath,
//     from: [
//       /var\s+deviceTypes\s*=\s*deviceOptions\.preferWebGl2\s*===\s*false\s*\?\s*\[pc\.DEVICETYPE_WEBGL1,\s*pc\.DEVICETYPE_WEBGL2\]\s*:\s*deviceOptions\.deviceTypes;\s*deviceTypes\.push\(LEGACY_WEBGL\);/gs,
//       /document\.head\.querySelector\('style'\)\.innerHTML\s*\+=\s*css;/g  // Matches the old querySelector for style
//     ],
//     to: [
//       'window.ASSET_PREFIX = "../../sample/"',  // Replacement for ASSET_PREFIX
//       `var deviceTypes = deviceOptions.preferWebGl2 === false ?
//         [pc.DEVICETYPE_WEBGL1, pc.DEVICETYPE_WEBGL2] :
//         deviceOptions.deviceTypes;
//       if (!deviceTypes) {
//         deviceTypes = [];
//       }
//       deviceTypes.push(LEGACY_WEBGL);`,  // Replacement for deviceTypes logic
//       `document.getElementById('import-style').innerHTML += css;`  // Replace with getElementById for 'import-style'

//     ],
//   };

//   // Perform the replacement
//   const results = await replaceInFile(options);

//   // Return the results or message
//   return results;
// }

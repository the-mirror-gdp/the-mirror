import replaceInFile from 'replace-in-file'

export async function modifySettings(filePath: string) {
  const options = {
    files: filePath,
    from: [
      /window\.ASSET_PREFIX\s*=\s*".*?"/g,
      /window\.SCRIPT_PREFIX\s*=\s*".*?"/g,
      /window\.SCENE_PATH\s*=\s*"(?:.*\/)?(\d+\.json)"/g,
      /'powerPreference'\s*:\s*".*?"/g
    ],
    to: [
      'window.ASSET_PREFIX = "../../sample/"',
      'window.SCRIPT_PREFIX = "../../sample"',
      'window.SCENE_PATH = "../../sample/$1"',
      '\'powerPreference\': "high-performance"'
    ]
  }

  await replaceInFile(options)
}

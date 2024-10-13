import { NextRequest, NextResponse } from 'next/server'
import formidable, { IncomingForm, Fields, Files } from 'formidable'
import fs from 'fs'
import path from 'path'
import unzipper from 'unzipper'
import { Readable } from 'stream'
import replaceInFile from 'replace-in-file'
import { modifySettings } from '@/utils/pc-import'

// Disable body parsing, formidable will handle it
export const config = {
  api: {
    bodyParser: false
  }
}

// Promisify formidable's form parsing
const parseForm = async (req: any) => {
  const form = new IncomingForm({ keepExtensions: true })

  return new Promise<{ fields: Fields; files: Files }>((resolve, reject) => {
    form.parse(req, (err, fields, files) => {
      if (err) reject(err)
      else resolve({ fields, files })
    })
  })
}

export async function POST(req: NextRequest) {
  try {
    // Convert the request's body to a Node.js readable stream
    const contentLength = req.headers.get('content-length')
    const contentType = req.headers.get('content-type')
    const destinationFilePath = 'temp/unzipped'

    if (!contentLength || !contentType) {
      return NextResponse.json(
        { error: 'Missing content headers' },
        { status: 400 }
      )
    }

    // Manually construct headers object for formidable
    const headers = {
      'content-length': contentLength,
      'content-type': contentType
    }

    // Create a Node.js Readable stream from the Web stream (req.body)
    const nodeReq = new Readable({
      read() {
        // Push the body content to the readable stream
        req.body
          ?.getReader()
          .read()
          .then(({ done, value }) => {
            if (done) this.push(null)
            else this.push(value)
          })
      }
    })

    nodeReq['headers'] = headers

    // Parse the form using formidable
    const { fields, files } = await parseForm(nodeReq)

    // Access the first file in the files array
    const fileArray = files.file as formidable.File[]
    const file = fileArray[0] // Access the first file

    if (!file || !file.filepath) {
      return NextResponse.json({ error: 'File not found' }, { status: 400 })
    }

    // Log the file path for debugging
    console.log('Uploaded file path:', file.filepath)

    // Unzip the uploaded file and find the settings file
    const unzippedFolderPath = await unzipFile(
      file.filepath,
      destinationFilePath
    )
    const settingsFilePath = path.join(
      unzippedFolderPath,
      '__settings__.import.js'
    )

    if (fs.existsSync(settingsFilePath)) {
      await modifySettings(settingsFilePath)
      return NextResponse.json({
        message: 'File uploaded and modified successfully!'
      })
    } else {
      return NextResponse.json(
        { error: 'Settings file not found in the uploaded zip' },
        { status: 404 }
      )
    }
  } catch (error) {
    console.error('Error processing the uploaded file:', error)
    return NextResponse.json(
      { error: 'Error processing the uploaded file' },
      { status: 500 }
    )
  }
}

// Unzip the file
async function unzipFile(
  filePath: string,
  destinationFilePath: string
): Promise<string> {
  const outputDir = path.join(process.cwd(), destinationFilePath)
  await fs.promises.mkdir(outputDir, { recursive: true })

  await fs
    .createReadStream(filePath)
    .pipe(unzipper.Extract({ path: outputDir }))

  return outputDir
}

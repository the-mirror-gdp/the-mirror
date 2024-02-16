export interface StorageFile {
  buffer: Buffer
  metadata: Map<string, string>
  contentType: string | undefined
}

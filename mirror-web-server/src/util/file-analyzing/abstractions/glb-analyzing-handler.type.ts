import { Document } from '@gltf-transform/core'

export type GLBAnalyzingHandler = (
  glbDocument: Document
) => boolean | Promise<boolean>

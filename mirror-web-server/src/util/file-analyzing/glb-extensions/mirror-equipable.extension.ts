import { Extension } from '@gltf-transform/core'

export class MirrorEquipableExtension extends Extension {
  extensionName = 'MIRROR_equipable'
  static EXTENSION_NAME = 'MIRROR_equipable'

  read() {
    return this
  }

  write() {
    return this
  }
}

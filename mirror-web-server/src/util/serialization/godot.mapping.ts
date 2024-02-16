export enum GodotTypes {
  BOOL = 1,
  INT = 2,
  FLOAT = 3,
  STRING = 4,
  VECTOR3 = 7,
  BASIS = 12,
  TRANSFORM = 13,
  DICTIONARY = 18,
  ARRAY = 19,
  POOL_BYTE_ARRAY = 20
}

// Arrays start with their 4-byte padded type code, then their 4 byte-padded length
// Ints are padded by 4 bytes
//

export function getGodotPaddingByType(type: number) {
  switch (type) {
    case GodotTypes.ARRAY:
    case GodotTypes.INT:
    case GodotTypes.STRING:
    case GodotTypes.FLOAT:
    case GodotTypes.VECTOR3:
    case GodotTypes.BASIS:
    case GodotTypes.DICTIONARY:
    case GodotTypes.TRANSFORM:
    case GodotTypes.POOL_BYTE_ARRAY:
    case GodotTypes.BOOL:
      return 4
  }
  throw new Error(`Failed to get padding for godot type: ${type}`)
}

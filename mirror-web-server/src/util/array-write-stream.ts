import { IBasis } from '../godot-types/basis.model'
import { ITransform } from '../godot-types/transform.model'
import { IVector3 } from '../godot-types/vector3.model'
import ArrayReadStream from './array-read.stream'
import {
  getGodotPaddingByType,
  GodotTypes
} from './serialization/godot.mapping'

export default class ArrayWriteStream {
  private index: number
  private buffer: Buffer
  private readonly ARRAY_START_SIZE = 1000

  constructor(length: number, eventCode: number) {
    this.buffer = Buffer.alloc(this.ARRAY_START_SIZE)
    this.index = 0
    this.writeType(GodotTypes.ARRAY)
    this.writeInt(length, false)
    this.writeInt(eventCode)
  }

  public copyBuffer(arrayReadStream: ArrayReadStream) {
    const startIndex =
      getGodotPaddingByType(GodotTypes.ARRAY) + // Skip Array padding
      getGodotPaddingByType(GodotTypes.INT) + // Skip Array length
      getGodotPaddingByType(GodotTypes.INT) + // Skip Event code type
      getGodotPaddingByType(GodotTypes.INT) // Skip Event code value

    const buffer = arrayReadStream.getBuffer()
    buffer.copy(this.buffer, startIndex, startIndex)
    this.index = buffer.length
  }

  public writeType(type: number) {
    this.buffer.writeInt32LE(type, this.index)
    this.index += 4
  }

  public writeBool(bool: boolean, encodeType = true) {
    if (encodeType) {
      this.writeType(GodotTypes.BOOL)
    }

    const num = Number(bool)
    this.writeInt(num, false)
  }

  public writeInt(value: number, encodeType = true): void {
    if (encodeType) {
      this.writeType(GodotTypes.INT)
    }
    this.buffer.writeInt32LE(value, this.index)
    this.index += 4
  }

  public writeFloat(value: number, encodeType = true): void {
    if (encodeType) {
      this.writeType(GodotTypes.FLOAT)
    }
    this.buffer.writeFloatLE(value, this.index)
    this.index += 4
  }

  public writeString(value: string, encodeType = true): void {
    if (encodeType) {
      this.writeType(GodotTypes.STRING)
    }
    const length = value.length
    this.writeInt(length, false) // Write length to buffer
    this.buffer.write(value, this.index, 'ascii')
    this.index += Math.ceil(length / 4) * 4
  }

  public writeVector3(vector3: IVector3, encodeType = true): void {
    if (encodeType) {
      this.writeType(GodotTypes.VECTOR3)
    }
    this.writeFloat(vector3.x, false)
    this.writeFloat(vector3.y, false)
    this.writeFloat(vector3.z, false)
  }

  public writeBasis(basis: IBasis, encodeType = true): void {
    if (encodeType) {
      this.writeType(GodotTypes.BASIS)
    }
    this.writeFloat(basis.x1, false)
    this.writeFloat(basis.y1, false)
    this.writeFloat(basis.z1, false)
    this.writeFloat(basis.x2, false)
    this.writeFloat(basis.y2, false)
    this.writeFloat(basis.z2, false)
    this.writeFloat(basis.x3, false)
    this.writeFloat(basis.y3, false)
    this.writeFloat(basis.z3, false)
  }

  public writeTransform(transform: ITransform, encodeType = true): void {
    if (encodeType) {
      this.writeType(GodotTypes.TRANSFORM)
    }
    this.writeBasis(transform.basis, false)
    this.writeVector3(transform.origin, false)
  }

  public writeDictionary<K, T>(
    dictionary: Map<K, T>,
    keyFunc: (key: K) => void,
    valueFunc: (value: T) => void
  ) {
    this.writeType(GodotTypes.DICTIONARY)

    const length = dictionary.size
    this.writeInt(length, false) // Write length to buffer

    const boundKeyFunc = keyFunc.bind(this)
    const boundValueFunc = valueFunc.bind(this)
    dictionary.forEach((value, key) => {
      boundKeyFunc(key)
      boundValueFunc(value)
    })
  }

  public writePoolByteArray(arr: Uint8Array, encoding = true) {
    if (encoding) {
      this.writeType(GodotTypes.POOL_BYTE_ARRAY)
    }

    this.buffer
    const length = arr.length
    this.writeInt(length, false)

    for (let i = 0; i < length; i++) {
      const byte = arr[i]
      this.buffer[this.index + i] = byte
    }
    this.index += length
  }

  public getBuffer(): Buffer {
    return this.buffer.subarray(0, this.index)
  }

  // Validates array start
  // Returns length
  public writeArray(length: number) {
    this.writeType(GodotTypes.ARRAY)
    this.writeInt(length, false)
  }
}

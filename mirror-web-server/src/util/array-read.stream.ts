import { InternalServerErrorException } from '@nestjs/common'
import { IBasis } from '../godot-types/basis.model'
import { ITransform } from '../godot-types/transform.model'
import { IVector3 } from '../godot-types/vector3.model'
import {
  getGodotPaddingByType,
  GodotTypes
} from './serialization/godot.mapping'

export default class ArrayReadStream {
  private index: number
  private dataView: DataView
  private buffer: Buffer

  constructor(buffer: Buffer) {
    this.buffer = buffer

    const uint8Array = new Uint8Array(buffer.length)
    for (let counter = 0; counter < buffer.length; counter++) {
      uint8Array[counter] = buffer[counter]
    }
    this.dataView = new DataView(uint8Array.buffer, 0, uint8Array.length)
    this.index = 0

    this.initBuffer()
  }

  private initBuffer() {
    this.readArray()
  }

  public getLength(): number {
    const lengthIndex = getGodotPaddingByType(GodotTypes.ARRAY) // Skip Array padding
    return this.dataView.getInt32(lengthIndex, true)
  }

  public getEventCode(): number {
    const eventCodeIndex =
      getGodotPaddingByType(GodotTypes.ARRAY) + // Skip Array padding
      getGodotPaddingByType(GodotTypes.INT) + // Skip Array length
      getGodotPaddingByType(GodotTypes.INT) // Skip Event code type
    return this.dataView.getInt32(eventCodeIndex, true)
  }

  public validateType(expectedType: GodotTypes) {
    const type = this.dataView.getInt32(this.index, true)
    if (type !== expectedType) {
      throw new InternalServerErrorException(
        `Data type ${type} does not match expected data type ${expectedType}`
      )
    }

    const padding = getGodotPaddingByType(type)
    this.index += padding
  }

  public readInt(validate = true): number {
    if (validate) {
      this.validateType(GodotTypes.INT)
    }
    if (this.dataView.byteLength > this.index) {
      const value = this.dataView.getInt32(this.index, true)
      this.index += 4
      return value
    } else {
      throw new InternalServerErrorException(
        'Could not read value of type "number"'
      )
    }
  }

  public readFloat(validate = true): number {
    if (validate) {
      this.validateType(GodotTypes.FLOAT)
    }
    if (this.dataView.byteLength > this.index) {
      const value = this.dataView.getFloat32(this.index, true)
      this.index += 4
      return value
    } else {
      throw new InternalServerErrorException(
        'Could not read value of type "float"'
      )
    }
  }

  private readStringLength(): number {
    const length = this.dataView.getInt32(this.index, true)
    this.index += 4
    return length
  }

  public readString(validate = true): string {
    if (validate) {
      this.validateType(GodotTypes.STRING)
    }
    const length = this.readStringLength()

    const textDecoder = new TextDecoder('ascii')
    const slice = this.dataView.buffer.slice(this.index, this.index + length)
    this.dataView.byteOffset
    const str = textDecoder.decode(slice)
    if (/[\u0080-\uffff]/.test(str)) {
      throw new Error('this string seems to contain (still encoded) multibytes')
    }
    this.index += Math.ceil(length / 4) * 4
    return str
  }

  public readVector3(validate = true): IVector3 {
    if (validate) {
      this.validateType(GodotTypes.VECTOR3)
    }
    const x = this.readFloat(false)
    const y = this.readFloat(false)
    const z = this.readFloat(false)
    return {
      x,
      y,
      z
    }
  }

  public readBasis(validate = true): IBasis {
    if (validate) {
      this.validateType(GodotTypes.BASIS)
    }
    const x1 = this.readFloat(false)
    const y1 = this.readFloat(false)
    const z1 = this.readFloat(false)
    const x2 = this.readFloat(false)
    const y2 = this.readFloat(false)
    const z2 = this.readFloat(false)
    const x3 = this.readFloat(false)
    const y3 = this.readFloat(false)
    const z3 = this.readFloat(false)
    return {
      x1,
      y1,
      z1,
      x2,
      y2,
      z2,
      x3,
      y3,
      z3
    }
  }

  public readBool(validate = true) {
    if (validate) {
      this.validateType(GodotTypes.BOOL)
    }

    const num = this.readInt(false)
    const bool = Boolean(num)
    return bool
  }

  public readPoolByteArray(): Uint8Array {
    this.validateType(GodotTypes.POOL_BYTE_ARRAY)
    let length = this.readInt(false)
    length = (length / 4) * 4
    const uint8Array = new Uint8Array(length)
    for (let i = 0; i < length; i++) {
      const byte = this.dataView.getUint8(this.index + i)
      uint8Array[i] = byte
    }
    this.index += length
    return uint8Array
  }

  public readTransform(validate = true) {
    if (validate) {
      this.validateType(GodotTypes.TRANSFORM)
    }
    const basis = this.readBasis(false)
    const origin = this.readVector3(false)

    return {
      basis,
      origin
    }
  }

  public readDictionary<K, T>(keyFunc: () => K, valueFunc: () => T) {
    this.validateType(GodotTypes.DICTIONARY)
    const length = this.readInt(false)

    const boundKeyFunc = keyFunc.bind(this)
    const boundValueFunc = valueFunc.bind(this)

    const dictionary = new Map<string, ITransform>()
    for (let i = 0; i < length; i++) {
      const key = boundKeyFunc()
      const transform = boundValueFunc()
      dictionary.set(key, transform)
    }

    return dictionary
  }

  // Validates array start
  // Returns length
  public readArray(validate = true): number {
    if (validate) {
      this.validateType(GodotTypes.ARRAY)
    }
    const length = this.readInt(false)
    return length
  }

  public readAll(): any[] {
    const array: any[] = []
    try {
      while (this.hasNext()) {
        const value = this.readNext()
        if (value) {
          array.push(value)
        }
      }
    } catch {
      return array
    }
  }

  public readNext(): any | any[] {
    const type = this.readInt(false)
    let value: any | any[]
    switch (type) {
      case GodotTypes.INT:
        value = this.readInt(false)
        break
      case GodotTypes.ARRAY:
        const arrayLength = this.readArray(false)
        value = []
        for (let i = 0; i < arrayLength; i++) {
          value = this.readNext()
        }
        break
      case GodotTypes.BOOL:
        value = this.readBool(false)
        break
      case GodotTypes.STRING:
        value = this.readString(false)
        break
      case GodotTypes.VECTOR3:
        value = this.readVector3(false)
        break
      case GodotTypes.TRANSFORM:
        value = this.readTransform(false)
        break
      case GodotTypes.FLOAT:
        value = this.readFloat(false)
        break
      case GodotTypes.BASIS:
        value = this.readBasis(false)
        break
    }
    return value
  }

  public hasNext(): boolean {
    return this.index <= this.buffer.length
  }

  public getBuffer(): Buffer {
    return this.buffer
  }
}

// database.types.ts is generated and the outputted type thinks that vec3s are number[] instead of [number, number, number], so this is used to update Database types imported so that forms and everything else line up nicely
// Vec3Keys, Vec4Keys, etc.should be regularly updated

import { Json, Tables } from '@/utils/database.types'

/**
 * Example usage:
 * export type DatabaseEntity = TransformTuples<
  Database['public']['Tables']['entities']['Row'],
  keyof TupleLengthMap>
 */

// Define a mapping of keys to their respective tuple lengths
export type TupleLengthMap = {
  local_position: 3
  local_scale: 3
  local_rotation: 4
  // Add more mappings as needed
}

// Utility type to transform arrays to tuples
// Utility type to transform arrays to tuples
export type TransformTuples<T> = Omit<T, keyof TupleLengthMap> & {
  [P in keyof TupleLengthMap & keyof T]: T[P] extends number[]
    ? TupleLengthMap[P] extends 3
      ? [number, number, number]
      : TupleLengthMap[P] extends 4
        ? [number, number, number, number]
        : TupleLengthMap[P] extends 2
          ? [number, number]
          : never
    : T[P] // If not a number array, keep the original type
}

// Example usage
// type ExampleEntity = {
//   local_position: number[]
//   local_rotation: number[]
//   local_scale: number[]
//   name: string
// }

// type TransformedEntity = TransformTuples<ExampleEntity>

import { z } from 'zod'
/**
 * Source of truth for the schemas of JSONB data in the DB with entities
 * Why? Postgres uses JSONSchema for JSON validation, which is fine, but it's a raw text string and hard to tweak/debug without tons of migrations and iterations.
 * We use zod elsewhere and there's a great zod-to-json schema library.
 * This allows us to use zod for JSON validation in the client AND we can copy-paste the JSONSchema conversion into our SQL definitions once it's hardened. (However, the client-side validation should take us pretty far bc it can be run right both at the form level and in the API request/RTK query before a DB insert in entitiesApi)
 */

export const entitySchema = z.object({
  name: z.string().nonempty(), // Non-empty string for the name

  enabled: z.boolean(),

  // Individual position components
  local_positionX: z.coerce.number(), // X component of local position
  local_positionY: z.coerce.number(), // Y component of local position
  local_positionZ: z.coerce.number(), // Z component of local position

  // Individual rotation components
  local_rotationX: z.coerce.number(), // X component of local rotation
  local_rotationY: z.coerce.number(), // Y component of local rotation
  local_rotationZ: z.coerce.number(), // Z component of local rotation

  // Individual scale components
  local_scaleX: z.coerce.number(), // X component of local scale
  local_scaleY: z.coerce.number(), // Y component of local scale
  local_scaleZ: z.coerce.number(), // Z component of local scale

  tags: z.array(z.string()).nullable().optional(), // Optional array of strings for tags

  components: z.any() // Assuming components is a JSON object, this could be updated further if there's a specific structure
})

import { z } from 'zod'
/**
 * Zod for Forms AND Postgres JsonSchema
 *
 * Source of truth for the schemas of JSONB data in the DB with entities
 * Why? Postgres uses JSONSchema for JSON validation, which is fine, but it's a raw text string and hard to tweak/debug without tons of migrations and iterations.
 * We use zod elsewhere and there's a great zod-to-json schema library.
 * This allows us to use zod for JSON validation in the client AND we can copy-paste the JSONSchema conversion into our SQL definitions once it's hardened. (However, the client-side validation should take us pretty far bc it can be run right both at the form level and in the API request/RTK query before a DB insert in entitiesApi)
 */

export const entitySchema = z.object({
  name: z.string(),

  enabled: z.boolean(),
  local_position: z.tuple([
    z.coerce.number(),
    z.coerce.number(),
    z.coerce.number()
  ]),
  // local_rotation: z.tuple([z.coerce.number(), z.coerce.number(), z.coerce.number()]),
  local_scale: z.tuple([
    z.coerce.number(),
    z.coerce.number(),
    z.coerce.number()
  ]),

  tags: z.array(z.string()).optional(), // Optional array of strings for tags

  components: z.any() // Assuming components is a JSON object, this could be updated further if there's a specific structure
})
export const entitySchemaUiFormDefaultValues = {
  name: '',
  enabled: true,
  local_position: [0, 0, 0] as [number, number, number],
  // local_rotation: [0, 0, 0] as [number,number,number],
  local_scale: [1, 1, 1] as [number, number, number],
  tags: [],
  components: {}
}

import { Checkbox } from '@/components/ui/checkbox'
import { FormItem, FormLabel } from '@/components/ui/form'
import { Input } from '@/components/ui/input'
import { Separator } from '@/components/ui/separator'
import { SyncedInputDepr } from '@/components/ui/synced-inputs/synced-input-old-form'
import {
  useGetSingleEntityQuery,
  useUpdateEntityMutation
} from '@/state/api/entities'
import { useFormContext } from 'react-hook-form'
import { z } from 'zod'

export const renderSchema = z.object({
  enabled: z.boolean(),
  type: z.string(),
  asset: z.number().nullable(),
  materialAssets: z.array(z.number().nullable()),
  layers: z.array(z.number()),
  batchGroupId: z.number().nullable(),
  castShadows: z.boolean(),
  castShadowsLightmap: z.boolean(),
  receiveShadows: z.boolean(),
  lightmapped: z.boolean(),
  lightmapSizeMultiplier: z.number(),
  isStatic: z.boolean(),
  rootBone: z.any().nullable()
})

export const RenderComponent = ({ entity }: { entity: any }) => {
  const form = useFormContext()

  return <></>
}

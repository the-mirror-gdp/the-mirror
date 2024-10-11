"use client";
import { DatabaseEntity, useGetSingleEntityQuery, useUpdateEntityMutation } from "@/state/entities";
import { Separator } from "@/components/ui/separator";
import InputVector3 from "@/components/ui/input.vector3";

export function EntityFormGroup({ entity }: { entity: DatabaseEntity }) {
  return (
    <>
      <InputVector3
        label="Position"
        entity={entity}
        dbColumnNameSnakeCase="local_position"
        defaultValues={[entity.local_position[0], entity.local_position[1], entity.local_position[2]]}
        useGetSingleGenericEntityQuery={useGetSingleEntityQuery}
        useUpdateGenericEntityMutation={useUpdateEntityMutation as any}
        propertiesToIncludeInUpdate={{
          scene_id: entity.scene_id,
          parent_id: entity.parent_id || undefined,
          order_under_parent: entity.order_under_parent || undefined,
        }}
      />

      <InputVector3
        label="Scale"
        entity={entity}
        dbColumnNameSnakeCase="local_scale"
        defaultValues={[entity.local_scale[0], entity.local_scale[1], entity.local_scale[2]]}
        useGetSingleGenericEntityQuery={useGetSingleEntityQuery}
        useUpdateGenericEntityMutation={useUpdateEntityMutation as any}
        propertiesToIncludeInUpdate={{
          scene_id: entity.scene_id,
          parent_id: entity.parent_id || undefined,
          order_under_parent: entity.order_under_parent || undefined,
        }}
      />

      <InputVector3
        label="Rotation"
        entity={entity}
        dbColumnNameSnakeCase="local_rotation"
        defaultValues={[entity.local_rotation[0], entity.local_rotation[1], entity.local_rotation[2]]}
        useGetSingleGenericEntityQuery={useGetSingleEntityQuery}
        useUpdateGenericEntityMutation={useUpdateEntityMutation as any}
        propertiesToIncludeInUpdate={{
          scene_id: entity.scene_id,
          parent_id: entity.parent_id || undefined,
          order_under_parent: entity.order_under_parent || undefined,
        }}
      />

      <Separator className="mt-1 mb-2" />
    </>
  );
}

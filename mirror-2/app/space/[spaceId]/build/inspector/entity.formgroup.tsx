"use client";
import { DatabaseEntity, useGetSingleEntityQuery, useUpdateEntityMutation } from "@/state/entities";
import { Separator } from "@/components/ui/separator";
import SyncedVector3Input from "@/components/ui/synced-inputs/synced-vector3-input";
import { SyncedTextInput } from "@/components/ui/synced-inputs/synced-text-input";
import { cn } from "@/lib/utils";
import { Input } from "antd";
import { z } from "zod";

export function EntityFormGroup({ entity }: { entity: DatabaseEntity }) {
  return (
    <>
      <SyncedTextInput
        id={entity.id}
        generalEntity={entity}
        defaultValue={entity.name}
        className={'p-0 m-0 bg-transparent cursor-pointer duration-0'}
        fieldName="name"
        formSchema={z.object({
          name: z.string().min(1, { message: "Entity name must be at least 1 character long" }),
        })}
        useGenericGetEntityQuery={useGetSingleEntityQuery}
        useGenericUpdateEntityMutation={useUpdateEntityMutation}
        renderComponent={(field) => (
          <Input
            type="text"
            autoComplete="off"
            className={cn("dark:bg-transparent py-1 pr-1 pl-0 text-lg border-none shadow-none tracking-wider hover:bg-[#ffffff0d] text-white")}
            {...field}
          />
        )}
      />

      <Separator className="mb-2" />

      <SyncedVector3Input
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

      <SyncedVector3Input
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

      <SyncedVector3Input
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

import { TwoWayInput } from "@/components/two-way-input";
import { Input } from "@/components/ui/input";
import { AxisLabelCharacter } from "@/components/ui/text/axis-label-character";
import { cn } from "@/lib/utils";
import { DatabaseEntity, useGetSingleEntityQuery, useUpdateEntityMutation } from "@/state/entities";
import { z } from 'zod'; // Import zod for validation
import * as pc from 'playcanvas'; // Import PlayCanvas for quaternion-to-Euler conversion
import { Separator } from "@/components/ui/separator";

// AxisInputGroup Component
function AxisInputGroup({
  axis,
  fieldName,
  defaultValue,
  formSchema,
  entity,
  ...rest
}: {
  axis: 'x' | 'y' | 'z';
  fieldName: string;
  defaultValue: string;
  formSchema: any;
  entity: any;
}) {
  return (
    <div className="flex items-center space-x-2"> {/* Flexbox for horizontal alignment */}
      <AxisLabelCharacter axis={axis} className="my-auto mr-3" /> {/* Axis label */}
      <TwoWayInput
        id={entity.id}
        fieldName={fieldName}
        formSchema={formSchema}
        defaultValue={defaultValue}
        generalEntity={entity}
        useGeneralGetEntityQuery={useGetSingleEntityQuery}
        useGeneralUpdateEntityMutation={useUpdateEntityMutation}
        renderComponent={(field) => (
          <Input
            type="number"
            autoComplete="off"
            className={cn("dark:bg-transparent px-1 py-0 pb-1 border-none shadow-none text-lg text-white")}
            {...field}
          />
        )}
        {...rest}
      />
    </div>
  );
}


export function EntityFormGroup({ entity }: { entity: DatabaseEntity }) {
  // Convert quaternion to Euler angles (X, Y, Z)
  const quaternion = new pc.Quat(entity.local_rotation[0], entity.local_rotation[1], entity.local_rotation[2], entity.local_rotation[3]);
  const eulerAngles = new pc.Vec3();
  quaternion.getEulerAngles(eulerAngles);

  const formSchema = z.object({
    // Local Position (X, Y, Z) - float numbers that are finite and safe
    localPositionX: z.coerce.number().finite().safe(),
    localPositionY: z.coerce.number().finite().safe(),
    localPositionZ: z.coerce.number().finite().safe(),

    // Local Scale (X, Y, Z) - float numbers, default to 1.0 for safe scaling
    localScaleX: z.coerce.number().finite().safe().default(1.0),
    localScaleY: z.coerce.number().finite().safe().default(1.0),
    localScaleZ: z.coerce.number().finite().safe().default(1.0),

    // Local Rotation (X, Y, Z) - Euler angles, finite and safe
    localRotationX: z.coerce.number().finite().safe(),
    localRotationY: z.coerce.number().finite().safe(),
    localRotationZ: z.coerce.number().finite().safe(),
  });

  return (
    <>
      {/* Name Field */}
      <TwoWayInput
        id={entity.id}
        fieldName="name"
        formSchema={formSchema} // Zod validation schema
        defaultValue={entity.name}
        generalEntity={entity}
        useGeneralGetEntityQuery={useGetSingleEntityQuery}
        useGeneralUpdateEntityMutation={useUpdateEntityMutation}
        renderComponent={(field) => (
          <Input
            type="text"
            autoComplete="off"
            className={cn("dark:bg-transparent p-1 border-none shadow-none text-lg text-white")}
            {...field}
          />
        )}
      />

      <Separator className="mt-1 mb-2" />

      {/* Grid Layout for Position, Scale, and Rotation */}
      <div className="grid grid-cols-4 gap-x-7 gap-y-2">
        {/* Position Row */}
        <div className="text-white mt-1">Position</div>
        <AxisInputGroup
          axis="x"
          fieldName="localPositionX"
          defaultValue={String(entity.local_position[0] ?? 0)}
          formSchema={formSchema}
          entity={entity}
        />
        <AxisInputGroup
          axis="y"
          fieldName="localPositionY"
          defaultValue={String(entity.local_position[1] ?? 0)}
          formSchema={formSchema}
          entity={entity}
        />
        <AxisInputGroup
          axis="z"
          fieldName="localPositionZ"
          defaultValue={String(entity.local_position[2] ?? 0)}
          formSchema={formSchema}
          entity={entity}
        />

        {/* Scale Row */}
        <div className="text-white mt-1">Scale</div>
        <AxisInputGroup
          axis="x"
          fieldName="localScaleX"
          defaultValue={String(entity.local_scale[0] ?? 1.0)}
          formSchema={formSchema}
          entity={entity}
        />
        <AxisInputGroup
          axis="y"
          fieldName="localScaleY"
          defaultValue={String(entity.local_scale[1] ?? 1.0)}
          formSchema={formSchema}
          entity={entity}
        />
        <AxisInputGroup
          axis="z"
          fieldName="localScaleZ"
          defaultValue={String(entity.local_scale[2] ?? 1.0)}
          formSchema={formSchema}
          entity={entity}
        />

        {/* Rotation Row */}
        <div className="text-white mt-1">Rotation</div>
        <AxisInputGroup
          axis="x"
          fieldName="localRotationX"
          defaultValue={String(eulerAngles.x ?? 0)}
          formSchema={formSchema}
          entity={entity}
        />
        <AxisInputGroup
          axis="y"
          fieldName="localRotationY"
          defaultValue={String(eulerAngles.y ?? 0)}
          formSchema={formSchema}
          entity={entity}
        />
        <AxisInputGroup
          axis="z"
          fieldName="localRotationZ"
          defaultValue={String(eulerAngles.z ?? 0)}
          formSchema={formSchema}
          entity={entity}
        />
      </div>
    </>
  );
}

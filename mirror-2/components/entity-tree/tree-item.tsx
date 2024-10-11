import { TwoWayInput } from "@/components/two-way-input";
import { Input } from "@/components/ui/input";
import { useGetSingleEntityQuery, useUpdateEntityMutation } from "@/state/entities";
import { cn } from "@/utils/cn";
import { useState } from "react";
import { z } from "zod";

export default function EntityTreeItem({ nodeData }) {

  return <div>
    {true && <TwoWayInput
      id={nodeData.id}
      generalEntity={nodeData}
      defaultValue={nodeData.name}
      className={'p-0 m-0 bg-transparent cursor-pointer duration-0'}
      fieldName="name"
      formSchema={z.object({
        name: z.string().min(1, { message: "Entity name must be at least 1 character long" }),
      })}
      useGeneralGetEntityQuery={useGetSingleEntityQuery}
      useGeneralUpdateEntityMutation={useUpdateEntityMutation}
      renderComponent={(field) => (
        <Input
          type="text"
          autoComplete="off"
          className={cn("dark:bg-transparent p-1 border-none shadow-none tracking-wider hover:bg-[#ffffff0d] text-white")}
          {...field}
        />
      )}
    />
    }
  </div>
}

import { TwoWayInput } from "@/components/two-way-input";
import { useGetSingleEntityQuery, useUpdateEntityMutation } from "@/state/entities";
import { useState } from "react";
import { z } from "zod";

export default function EntityTreeItem({ nodeData }) {

  return <div>
    {true && <TwoWayInput
      id={nodeData.id}
      generalEntity={nodeData}
      defaultValue={nodeData.name}
      className={'p-0 m-0 h-8 text-base font-light font-sans tracking-wide bg-transparent cursor-pointer'}
      fieldName="name"
      formSchema={z.object({
        name: z.string().min(1, { message: "Entity name must be at least 1 character long" }),
      })}
      useGeneralGetEntityQuery={useGetSingleEntityQuery}
      useGeneralUpdateEntityMutation={useUpdateEntityMutation}
    />
    }
  </div>
}

import { Checkbox } from "@/components/ui/checkbox";
import { Input } from "@/components/ui/input";
import { Select } from "@/components/ui/select";
import { useForm, Controller } from "react-hook-form";

// Define the types for the form data configuration
interface FormFieldConfig {
  type: "text" | "boolean" | "multiselect" | "vector3" | "dropdown";
  label: string;
  value: any;
  options?: string[]; // for dropdown and multiselect
}

// Sample data input could look like this
const dbItem: Record<string, FormFieldConfig> = {
  name: { type: "text", label: "Name", value: "Example" },
  active: { type: "boolean", label: "Active", value: true },
  categories: { type: "multiselect", label: "Categories", options: ["Category1", "Category2"], value: [] },
  position: { type: "vector3", label: "Position", value: { x: 0, y: 0, z: 0 } },
  status: { type: "dropdown", label: "Status", options: ["Pending", "Completed"], value: "Pending" },
};

interface DynamicFormGroupProps {
  formData?: Record<string, FormFieldConfig>;
}

export default function DynamicFormGroup({ formData = dbItem }: DynamicFormGroupProps) {
  const { control, handleSubmit } = useForm({
    defaultValues: Object.keys(formData).reduce((acc, key) => {
      acc[key] = formData[key].value;
      return acc;
    }, {} as Record<string, any>),
  });

  const onSubmit = (data: any) => {
    console.log(data); // Submit the form data
  };

  const renderField = (name: string, config: FormFieldConfig) => {
    switch (config.type) {
      case "text":
        return (
          <Controller
            name={name}
            control={control}
            render={({ field }) => <Input placeholder={config.label} {...field} />}
          />
        );
      case "boolean":
        return (
          <Controller
            name={name}
            control={control}
            render={({ field }) => (
              <Checkbox checked={field.value} onCheckedChange={field.onChange}>
                {config.label}
              </Checkbox>
            )}
          />
        );
      // case "multiselect":
      //   return (
      //     <Controller
      //       name={name}
      //       control={control}
      //       render={({ field }) => (
      //         <Select
      //           placeholder={config.label}
      //           value={field.value}
      //           onChange={field.onChange}
      //         >
      //           {config.options?.map((option) => (
      //             <option key={option} value={option}>
      //               {option}
      //             </option>
      //           ))}
      //         </Select>
      //       )}
      //     />
      //   );
      case "vector3":
        return (
          <div>
            <label>{config.label}</label>
            <div className="grid grid-cols-3 gap-2">
              <Controller
                name={`${name}.x`}
                control={control}
                render={({ field }) => <Input type="number" placeholder="X" {...field} />}
              />
              <Controller
                name={`${name}.y`}
                control={control}
                render={({ field }) => <Input type="number" placeholder="Y" {...field} />}
              />
              <Controller
                name={`${name}.z`}
                control={control}
                render={({ field }) => <Input type="number" placeholder="Z" {...field} />}
              />
            </div>
          </div>
        );
      case "dropdown":
        return (
          <Controller
            name={name}
            control={control}
            render={({ field }) => (
              <Select {...field}>
                {config.options?.map((option) => (
                  <option key={option} value={option}>
                    {option}
                  </option>
                ))}
              </Select>
            )}
          />
        );
      default:
        return null;
    }
  };

  return (
    <form onSubmit={handleSubmit(onSubmit)}>
      {Object.keys(formData).map((key) => (
        <div key={key} className="mb-4">
          {renderField(key, formData[key])}
        </div>
      ))}
      <button type="submit" className="btn btn-primary">Submit</button>
    </form>
  );
}

import { Button } from "@/components/ui/button";
import { useGetFileUpload } from "@/hooks/file-upload";
import { FileUp } from "lucide-react";
import { useDropzone } from "react-dropzone";

export default function AssetUploadButton() {
  const onDrop = useGetFileUpload()
  // file dropzone
  const { getRootProps, getInputProps, open, acceptedFiles } = useDropzone({ onDrop });

  return (
    <>
      <input {...getInputProps()} />
      <Button className="w-full mb-4" type="button" onClick={() => open()}>
        <FileUp className="size-7 mr-2" />
        Upload Asset
      </Button>
    </>
  )
}

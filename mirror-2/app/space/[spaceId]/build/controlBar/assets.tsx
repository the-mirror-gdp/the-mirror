'use client';
import AssetThumbnail from '@/components/ui/asset-thumbnail';
import { Button } from '@/components/ui/button';
import { ContextMenu, ContextMenuContent, ContextMenuItem, ContextMenuTrigger } from '@/components/ui/context-menu';
import AssetUploadButton from '@/components/ui/custom-buttons/asset-upload.button';
import { Form, FormControl, FormField, FormItem, FormMessage, FormSuccessMessage } from '@/components/ui/form';
import { Input } from '@/components/ui/input';
import { useLazySearchAssetsQuery, useLazyGetUserMostRecentlyUpdatedAssetsQuery, useLazyDownloadAssetQuery } from '@/state/api/assets';

import downloadFile from '@/utils/download-file';
import { createSupabaseBrowserClient } from '@/utils/supabase/client';
import { zodResolver } from '@hookform/resolvers/zod';
import { ScrollArea } from '@radix-ui/react-scroll-area';
import { useThrottleCallback } from '@react-hook/throttle';
import { FileDown, XIcon } from 'lucide-react';
import { useEffect, useState } from 'react';
import { useForm } from 'react-hook-form';
import { z } from "zod";

const formSchema = z.object({
  text: z.string().min(3)
})

export default function Assets() {
  const [selectedAssetId, setSelectedAssetId] = useState<string | null>(null);

  // Define the form
  const form = useForm<z.infer<typeof formSchema>>({
    resolver: zodResolver(formSchema),
    mode: "onChange",
    defaultValues: {
      text: "",
    },
  });

  const [triggerSearch, { data: assets, isLoading, isSuccess, error }] = useLazySearchAssetsQuery();
  const [triggerGetUserMostRecentlyUpdatedAssets, { data: recentAssets }] = useLazyGetUserMostRecentlyUpdatedAssetsQuery({});
  const [triggerDownloadAsset] = useLazyDownloadAssetQuery();

  const throttledSubmit = useThrottleCallback(() => {
    triggerSearch({ text: form.getValues("text")?.trim() });
  }, 3, true);

  async function onSubmit(values: z.infer<typeof formSchema>) {
    throttledSubmit();
  }

  // Watch the text input value
  useEffect(() => {
    const subscription = form.watch(({ text }, { name, type }) => {
      if (text && text?.length >= 3) {
        form.handleSubmit(onSubmit)();
      }
    });
    return () => subscription.unsubscribe();
  }, []);

  useEffect(() => {
    triggerGetUserMostRecentlyUpdatedAssets({});
  }, [triggerGetUserMostRecentlyUpdatedAssets]);

  // Handle download action from the context menu
  const handleDownload = async (assetId: string) => {
    // const { data, error } = await triggerDownloadAsset({ assetId });
    const supabase = createSupabaseBrowserClient();

    const { data, error } = await supabase.storage
      .from('assets')  // Use your actual bucket name
      .download(`users/${assetId}`);

    if (data) {
      // Use the helper function to trigger the file download
      downloadFile(data, `${assetId}.jpg`); // Customize the filename as needed
    }
  };

  return (
    <>
      {/* Search bar */}
      <Form {...form}>
        <form onSubmit={form.handleSubmit(onSubmit)} className="w-full">
          <FormField
            control={form.control}
            name="text"
            render={({ field }) => (
              <FormItem>
                <FormControl>
                  <div className="relative">
                    <Input
                      type="text"
                      placeholder="Search"
                      className="mb-4 w-full"
                      {...field}
                    />
                    {
                      form.formState.isDirty && <Button
                        type="button"
                        variant="ghost"
                        size="icon"
                        className="absolute right-1 top-1/4 -translate-y-1/4 h-7 w-7 text-gray-500 hover:text-gray-900 dark:text-gray-400 dark:hover:text-gray-100"
                        onClick={() => form.reset()}
                      >
                        <XIcon className="h-4 w-4" />
                        <span className="sr-only">Clear</span>
                      </Button>
                    }
                  </div>
                </FormControl>
                <FormMessage />
                <FormSuccessMessage>{assets?.length} Results</FormSuccessMessage>
              </FormItem>
            )}
          />
        </form>
      </Form>

      {/* Asset Upload Button */}
      <AssetUploadButton />

      {/* Scrollable area that takes up remaining space */}
      <div className="flex-1 overflow-auto">
        <ScrollArea className="">
          <div className="grid grid-cols-[repeat(auto-fill,minmax(80px,1fr))] gap-4 pb-40">
            {form.formState.isSubmitted ? assets?.map((asset) => (
              <ContextMenu key={asset.id}>
                <ContextMenuTrigger asChild onContextMenu={() => setSelectedAssetId(asset.id)}>
                  <div>
                    <AssetThumbnail name={asset.name} imageUrl={asset.thumbnail_url} />
                  </div>
                </ContextMenuTrigger>
                <ContextMenuContent>
                  <ContextMenuItem onClick={() => selectedAssetId && handleDownload(selectedAssetId)}>
                    <FileDown className="mr-2" />
                    Download
                  </ContextMenuItem>
                </ContextMenuContent>
              </ContextMenu>
            )) : recentAssets?.map((asset) => (
              <ContextMenu key={asset.id}>
                <ContextMenuTrigger asChild onContextMenu={() => setSelectedAssetId(asset.id)}>
                  <div>
                    <AssetThumbnail name={asset.name} imageUrl={asset.thumbnail_url} />
                  </div>
                </ContextMenuTrigger>
                <ContextMenuContent>
                  <ContextMenuItem onClick={() => selectedAssetId && handleDownload(selectedAssetId)}>
                    <FileDown className="mr-2" />
                    Download
                  </ContextMenuItem>
                </ContextMenuContent>
              </ContextMenu>
            ))}
          </div>
        </ScrollArea>
      </div>
    </>
  );
}

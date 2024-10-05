'use client';
import { useEffect, useState } from 'react';
import { Input } from '@/components/ui/input';
import { Button } from '@/components/ui/button';
import { Box, FileUp, PlusCircleIcon, XIcon } from 'lucide-react';
import { z } from "zod";
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { Form, FormField, FormItem, FormControl, FormMessage, FormSuccessMessage } from '@/components/ui/form';
import { useLazyGetUserMostRecentlyUpdatedAssetsQuery, useLazySearchAssetsQuery } from '@/state/supabase';
import { useThrottleCallback } from '@react-hook/throttle'
import { Tables } from '@/utils/database.types';
import AssetThumbnail from '@/components/ui/asset-thumbnail';
import { ScrollArea } from '@radix-ui/react-scroll-area';
import { useDropzone } from 'react-dropzone';
import AssetUploadButton from '@/components/ui/custom-buttons/asset-upload.button';
import { useGetFileUpload } from '@/hooks/file-upload';

const formSchema = z.object({
  text: z.string().min(3)
})

export default function Assets() {
  // define the form
  const form = useForm<z.infer<typeof formSchema>>({
    resolver: zodResolver(formSchema),
    mode: "onChange",
    defaultValues: {
      text: "",
    },
    // errors: error TODO add error handling here
  })
  const [triggerSearch, { data: assets, isLoading, isSuccess, error }] = useLazySearchAssetsQuery()
  const [triggerGetUserMostRecentlyUpdatedAssets, { data: recentAssets }] = useLazyGetUserMostRecentlyUpdatedAssetsQuery({})

  const throttledSubmit = useThrottleCallback(() => {
    triggerSearch({ text: form.getValues("text")?.trim() })
  }, 3, true) // the 4 if 4 FPS 
  // 2. Define a submit handler.
  async function onSubmit(values: z.infer<typeof formSchema>) {
    throttledSubmit()
  }

  // file dropzone
  const onDrop = useGetFileUpload()

  const { getRootProps, getInputProps, open, acceptedFiles } = useDropzone({
    // Disable click and keydown behavior
    noClick: true,
    noKeyboard: true,
    onDrop
  });

  // Watch the text input value
  useEffect(() => {
    const subscription = form.watch(({ text }, { name, type }) => {
      if (text && text?.length >= 3) {
        form.handleSubmit(onSubmit)()
      }
    })
    return () => subscription.unsubscribe()
  }, [])

  useEffect(() => {
    triggerGetUserMostRecentlyUpdatedAssets({})
  }, [triggerGetUserMostRecentlyUpdatedAssets])

  return (
    <div className="flex flex-col p-4" {...getRootProps()}>
      {/* Search bar */}
      <Form {...form} >
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
                    <Button
                      type="button"
                      variant="ghost"
                      size="icon"
                      className="absolute right-1 top-1/4 -translate-y-1/4 h-7 w-7 text-gray-500 hover:text-gray-900 dark:text-gray-400 dark:hover:text-gray-100"
                      onClick={() => {
                        form.reset()
                      }}
                    >
                      <XIcon className="h-4 w-4" />
                      <span className="sr-only">Clear</span>
                    </Button>
                  </div>
                </FormControl>
                {/* TODO add better styling for this so it doesn't shift the input field */}
                <FormMessage />
                <FormSuccessMessage >{assets?.length} Results</FormSuccessMessage>
              </FormItem>
            )}
          />
        </form>
      </Form >

      {/* Asset Upload Button */}
      <AssetUploadButton />


      {/* Scrollable area that takes up remaining space */}
      <div className="flex-1 overflow-auto">
        <ScrollArea className="h-screen">
          <div className="grid grid-cols-[repeat(auto-fill,minmax(80px,1fr))] gap-4 pb-40">
            {form.formState.isSubmitted ? assets?.map((asset, index) => (
              <AssetThumbnail name={asset.name} imageUrl={asset.thumbnail_url} />
            )) : recentAssets?.map((asset) => (
              <AssetThumbnail name={asset.name} imageUrl={asset.thumbnail_url} />
            ))}
          </div>
        </ScrollArea>
      </div>
    </div>
  );
}

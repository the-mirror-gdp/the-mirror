'use client';
import { useEffect, useState } from 'react';
import { Input } from '@/components/ui/input';
import { Button } from '@/components/ui/button';
import { XIcon } from 'lucide-react';
import { z } from "zod";
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { Form, FormField, FormItem, FormControl, FormMessage, FormSuccessMessage } from '@/components/ui/form';
import { useLazySearchAssetsQuery } from '@/state/supabase';
import { useThrottleCallback } from '@react-hook/throttle'

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

  const throttledSubmit = useThrottleCallback(() => {
    triggerSearch({ text: form.getValues("text") })
  }, 3, true) // the 4 if 4 FPS 
  // 2. Define a submit handler.
  async function onSubmit(values: z.infer<typeof formSchema>) {
    throttledSubmit()
  }

  // Watch the text input value
  useEffect(() => {
    const subscription = form.watch(({ text }, { name, type }) => {
      if (text && text?.length >= 3) {
        form.handleSubmit(onSubmit)()
      }
    })
    return () => subscription.unsubscribe()
  }, [])

  return (
    <div className="flex flex-col">
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


      {/* Scrollable area that takes up remaining space */}
      <div className="flex-1 overflow-auto">
        <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-4 p-4 pb-16">
          {assets?.map((image, index) => (
            <div key={index} className="text-center ">
              <img
                src={image.src}
                alt={image.text}
                className="w-full h-auto rounded-lg mb-2"
              />
              <p>{image.text}</p>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}

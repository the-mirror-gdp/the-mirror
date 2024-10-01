import { atom } from "jotai";

export const controlBarCurrentViewAtom = atom("scene");

export const assetsAtom = atom([]);

export const asyncTimeoutAtom = atom(async (get) => {
  // Simulate an asynchronous task with a timeout
  await new Promise((resolve) => setTimeout(resolve, 1));

  return 'Data after timeout';
});

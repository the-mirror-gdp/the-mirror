// Separate hooks to manage UI audio with state so that the UI components are agnostic to it
"use client"
import { useAppSelector } from "@/hooks/hooks";
import { selectUiSoundsCanPlay } from "@/state/local";
import { atomWithStorage } from 'jotai/utils';
import { useEffect, useState } from "react";
import useSound from "use-sound";

export const uiSoundsCanPlayAtom = atomWithStorage('uiSoundsCanPlay', true);

export function useUiHoverSoundEffect() {
  const uiSoundsCanPlay = useAppSelector(selectUiSoundsCanPlay);

  const [canPlayAudioFromUserGestureTrack, setCanPlayAudioFromUserGestureTrack] = useState(false);
  const [playSound] = useSound("/sounds/hover_menu.wav", {
    volume: 0.05,
    interrupt: true
  });
  const play = function () {
    if (uiSoundsCanPlay && canPlayAudioFromUserGestureTrack) {
      playSound();
    }
  }

  useEffect(() => {
    // Function to enable audio after the first user gesture
    const enableAudioPlayback = () => {
      setCanPlayAudioFromUserGestureTrack(true);
      window.removeEventListener("click", enableAudioPlayback); // Only trigger once
    };

    // Listen for the first user gesture
    window.addEventListener("click", enableAudioPlayback);

    return () => {
      // Cleanup event listener
      window.removeEventListener("click", enableAudioPlayback);
    };
  }, []);

  return [play];
}

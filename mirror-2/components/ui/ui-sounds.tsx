// Separate hooks to manage UI audio with state so that the UI components are agnostic to it
"use client"
import { atom, useAtom, useAtomValue } from "jotai";
import { cloneElement, isValidElement, useEffect, useRef, useState } from "react";
import useSound from "use-sound";

export const uiSoundsCanPlayAtom = atom(true);

export function useAudioCanPlay() {
  const [uiSoundsCanPlay, setUiSoundsCanPlay] = useAtom(uiSoundsCanPlayAtom);

  return { uiSoundsCanPlay, setUiSoundsCanPlay };
}

export function useUiHoverSoundEffect() {
  const audioCanPlayUserSetting = useAtomValue(uiSoundsCanPlayAtom)
  const [canPlayAudioFromUserGestureTrack, setCanPlayAudioFromUserGestureTrack] = useState(false);
  const [playSound] = useSound("/sounds/hover_menu.wav", {
    volume: 0.05,
    interrupt: true
  });
  const play = function () {
    if (audioCanPlayUserSetting && canPlayAudioFromUserGestureTrack) {
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

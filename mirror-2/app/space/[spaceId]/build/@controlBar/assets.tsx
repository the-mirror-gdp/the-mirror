'use client';
import { asyncTimeoutAtom } from "@/app/space/[spaceId]/build/@controlBar/store";
import { useGetPokemonByNameQuery } from "@/state/pokemon";
import { useAtom } from "jotai";
import { Suspense } from "react";

export default function Assets() {
  const { data, error, isLoading } = useGetPokemonByNameQuery('bulbasaur')

  const [test] = useAtom(asyncTimeoutAtom);
  return (
    <div>Assets: {JSON.stringify(data)}</div>
  );
}

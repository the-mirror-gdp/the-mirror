'use client';
import { useGetPokemonByNameQuery } from "@/state/pokemon";

export default function Assets() {
  const { data, error, isLoading } = useGetPokemonByNameQuery('bulbasaur')

  return (
    <div>Assets: {JSON.stringify(data)}</div>
  );
}

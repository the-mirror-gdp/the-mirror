'use client'
import { useCallback, useRef } from 'react'
import { useUpdateEntityMutation } from '@/state/api/entities'
import { debounce } from 'lodash'

// This currently has a 1ms debounce; it was firing onChange in the input earlier, but decided to use onBlur. However, keeping this code so we can tweak UX if desired
const useReduxInputSync = () => {
  const [updateEntity] = useUpdateEntityMutation()
  const entityUpdatesRef = useRef(new Map())

  const debouncedUpdate = useCallback(
    debounce(async () => {
      entityUpdatesRef.current.forEach(async (updatedData, entityId) => {
        console.log('debounce: calling update', updatedData)
        await updateEntity({ id: entityId, ...updatedData })
      })
      entityUpdatesRef.current.clear()
    }, 1),
    []
  )

  const updateReduxWithDebounce = (entityId, updatedData) => {
    if (!entityUpdatesRef.current.has(entityId)) {
      entityUpdatesRef.current.set(entityId, updatedData)
    } else {
      const existingData = entityUpdatesRef.current.get(entityId)
      entityUpdatesRef.current.set(entityId, {
        ...existingData,
        ...updatedData
      })
    }
    debouncedUpdate()
  }

  return { updateReduxWithDebounce }
}

export default useReduxInputSync

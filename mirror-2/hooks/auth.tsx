'use client'
import { useAppDispatch, useAppSelector } from '@/hooks/hooks'
import { updateLocalUserState, clearLocalUserState } from '@/state/local.slice'
import { createSupabaseBrowserClient } from '@/utils/supabase/client'
import { useRouter } from 'next/navigation'

export function useSetupAuthEvents() {
  const supabase = createSupabaseBrowserClient()
  const dispatch = useAppDispatch()
  const router = useRouter()

  // if no user, clear local state. TODO update this to use a Context
  // useEffect(() => {
  //   async function clearStateIfNoUser() {
  //     const user = await supabase.auth.getSession()
  //     if (!user) {
  //       dispatch(clearLocalUserState())
  //     }
  //   }
  //   clearStateIfNoUser()
  // }, [dispatch, supabase])

  const { data: authListener } = supabase.auth.onAuthStateChange(
    (event, session) => {
      function handleLogin() {
        if (session?.user) {
          // console.log('auth: DID fire')
          // console.log("updateLocalUserState", event, session?.user)
          const { id, email, is_anonymous } = session.user
          dispatch(updateLocalUserState({ id, email, is_anonymous }))
        } else {
          console.log('auth: did not fire')
        }
      }

      function handleLogout() {
        dispatch(clearLocalUserState())
        if (typeof window !== 'undefined') {
          router.push('/login')
        }
      }
      // console.log("auth", event, session)
      if (event === 'INITIAL_SESSION') {
        // handle initial session
        if (session?.user) {
          handleLogin()
        } else {
          handleLogout()
        }
      } else if (event === 'SIGNED_IN') {
        // handle sign in event
        handleLogin()
      } else if (event === 'SIGNED_OUT') {
        // handle sign out event
        handleLogout()
      } else if (event === 'PASSWORD_RECOVERY') {
        // handle password recovery event
      } else if (event === 'TOKEN_REFRESHED') {
        // handle token refreshed event
      } else if (event === 'USER_UPDATED') {
        // handle user updated event
      }
    }
  )

  // Cleanup the subscription when the component is unmounted
  return () => {
    authListener.subscription.unsubscribe()
  }
}

export function useRedirectToHomeIfSignedIn() {
  const router = useRouter()
  const id = useAppSelector((state) => state.local?.user?.id)
  console.log('auth router check', id)
  if (id) {
    router.replace('/home')
  }
}

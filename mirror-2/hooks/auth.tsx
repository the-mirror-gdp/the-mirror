import { useAppDispatch, useAppSelector } from "@/hooks/hooks";
import { updateLocalUserState, clearLocalUserState } from "@/state/local";
import { createSupabaseBrowserClient } from "@/utils/supabase/client";
import { useRouter } from "next/navigation";

export function useSetupAuthEvents() {
  const supabase = createSupabaseBrowserClient();
  const dispatch = useAppDispatch();

  const { data: authListener } = supabase.auth.onAuthStateChange((event, session) => {
    console.log("auth", event, session)

    if (event === 'INITIAL_SESSION') {
      // handle initial session
    } else if (event === 'SIGNED_IN') {
      // handle sign in event
      if (session?.user) {
        console.log("updateLocalUserState", event, session?.user)
        const { id, email, is_anonymous } = session.user
        dispatch(updateLocalUserState({ id, email, is_anonymous }))
      }
    } else if (event === 'SIGNED_OUT') {
      // handle sign out event
      clearLocalUserState()
    } else if (event === 'PASSWORD_RECOVERY') {
      // handle password recovery event
    } else if (event === 'TOKEN_REFRESHED') {
      // handle token refreshed event
    } else if (event === 'USER_UPDATED') {
      // handle user updated event
    }
  })

  // Cleanup the subscription when the component is unmounted
  return () => {
    authListener.subscription.unsubscribe()
  };
}

export function useRedirectToHomeIfSignedIn() {
  const router = useRouter()
  const id = useAppSelector(state => state.local?.user?.id);
  if (id) {
    router.replace("/home")
  }
}

import { BlankRedirect } from '@/app/protected/blank-redirect'
import { createServerClient } from '@/utils/supabase/server'
import { redirect } from 'next/navigation'

export default async function ProtectedPage() {
  const supabase = createServerClient()

  const {
    data: { user }
  } = await supabase.auth.getUser()

  if (!user) {
    return redirect('/login')
  }

  return (
    // delete this page eventually. it's here from boilerplate auth that users server side
    <BlankRedirect />
  )
}

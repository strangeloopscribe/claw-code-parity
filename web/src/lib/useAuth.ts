import { useEffect, useState } from 'react'
import type { Session } from '@supabase/supabase-js'
import { supabase } from './supabase'

export type AuthState = {
  loading: boolean
  session: Session | null
  familyId: string | null
  displayName: string | null
  error: string | null
}

// Ensures the signed-in user has a profile and belongs to a family.
// Runs once per sign-in so onboarding is invisible to the user.
async function bootstrap(session: Session): Promise<{ familyId: string; displayName: string }> {
  const userId = session.user.id
  const fallbackName = session.user.email?.split('@')[0] ?? 'Me'

  // 1. Ensure a profile row exists.
  const { data: profile } = await supabase
    .from('profiles')
    .select('id, display_name')
    .eq('id', userId)
    .maybeSingle()

  let displayName = profile?.display_name ?? fallbackName
  if (!profile) {
    await supabase.from('profiles').insert({
      id: userId,
      display_name: displayName,
      color: '#ff7043',
    })
  }

  // 2. Ensure the user belongs to a family.
  const { data: membership } = await supabase
    .from('family_members')
    .select('family_id')
    .eq('profile_id', userId)
    .maybeSingle()

  if (membership) {
    return { familyId: membership.family_id, displayName }
  }

  // 3. No family yet — create one and join it.
  const { data: family, error: famErr } = await supabase
    .from('families')
    .insert({ name: 'My Family', created_by: userId })
    .select('id')
    .single()
  if (famErr || !family) throw famErr ?? new Error('Could not create family')

  await supabase.from('family_members').insert({
    family_id: family.id,
    profile_id: userId,
    role: 'admin',
  })

  return { familyId: family.id, displayName }
}

export function useAuth(): AuthState {
  const [state, setState] = useState<AuthState>({
    loading: true,
    session: null,
    familyId: null,
    displayName: null,
    error: null,
  })

  useEffect(() => {
    let active = true

    async function handle(session: Session | null) {
      if (!session) {
        if (active) setState({ loading: false, session: null, familyId: null, displayName: null, error: null })
        return
      }
      try {
        const { familyId, displayName } = await bootstrap(session)
        if (active) setState({ loading: false, session, familyId, displayName, error: null })
      } catch (e) {
        const msg = e instanceof Error ? e.message : 'Something went wrong'
        if (active) setState({ loading: false, session, familyId: null, displayName: null, error: msg })
      }
    }

    supabase.auth.getSession().then(({ data }) => handle(data.session))
    const { data: sub } = supabase.auth.onAuthStateChange((_event, session) => handle(session))

    return () => {
      active = false
      sub.subscription.unsubscribe()
    }
  }, [])

  return state
}

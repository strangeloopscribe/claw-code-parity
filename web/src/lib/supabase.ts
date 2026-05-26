import { createClient } from '@supabase/supabase-js'
import { SUPABASE_URL, SUPABASE_ANON_KEY } from './config'

export const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
  auth: {
    persistSession: true,
    autoRefreshToken: true,
  },
})

export type FamilyEvent = {
  id: string
  family_id: string
  created_by: string
  title: string
  description: string | null
  location: string | null
  start_time: string
  end_time: string | null
  all_day: boolean
  color: string | null
}

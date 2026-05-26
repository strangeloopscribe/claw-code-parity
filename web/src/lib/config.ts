// Supabase connection settings.
//
// The publishable (anon) key is DESIGNED to be exposed in client-side code —
// your data is protected by Row Level Security policies in the database, not by
// hiding this key. So it's safe to commit. To point at a different project,
// just change these two values (or override via VITE_ env vars at build time).

export const SUPABASE_URL =
  import.meta.env.VITE_SUPABASE_URL ?? 'https://osqicajjvcrybogsejvl.supabase.co'

export const SUPABASE_ANON_KEY =
  import.meta.env.VITE_SUPABASE_ANON_KEY ??
  'sb_publishable_YiI8zAR317sZC8kam5u1MA_ax6bIo1h'

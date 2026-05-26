# Family Hub — Web App (PWA)

A web-based family organizer that installs to your home screen on iPad, iPhone,
Android, and PC. Talks directly to your existing Supabase backend.

**Current feature:** shared family calendar (more coming — lists, journal).

## Deploy (one-time, works from your iPad browser)

1. Go to [netlify.com](https://app.netlify.com) and sign in with GitHub.
2. **Add new site → Import an existing project →** pick `claw-code-parity`.
3. Netlify reads `web/netlify.toml` automatically (base `web`, build `npm run build`, publish `dist`).
4. Click **Deploy**. You get a permanent URL like `family-hub-xyz.netlify.app`.
5. Open that URL on any device → **Share → Add to Home Screen** to install it like an app.

Every time code is pushed to the branch, Netlify rebuilds automatically.

## Run locally (optional, needs Node 18+)

```bash
cd web
npm install
npm run dev
```

## Supabase config

Connection lives in `src/lib/config.ts`. The publishable key is safe to commit —
data is protected by Row Level Security, not by hiding the key. Override with
`VITE_SUPABASE_URL` / `VITE_SUPABASE_ANON_KEY` env vars if needed.

## Onboarding

First sign-in auto-creates your profile and a family ("My Family") behind the
scenes — no setup screens. Invite codes and multi-member families come in a
later iteration.

import { useAuth } from './lib/useAuth'
import { Login } from './pages/Login'
import { CalendarPage } from './pages/CalendarPage'

export default function App() {
  const auth = useAuth()

  if (auth.loading) {
    return (
      <div className="app">
        <div className="loader">Loading…</div>
      </div>
    )
  }

  if (!auth.session) {
    return <Login />
  }

  if (auth.error || !auth.familyId) {
    return (
      <div className="app">
        <div className="loader" style={{ flexDirection: 'column', gap: 12, padding: 24, textAlign: 'center' }}>
          <p>Couldn't finish setting up your family.</p>
          {auth.error && <p style={{ fontSize: 13, color: '#c0392b' }}>{auth.error}</p>}
          <button className="link-btn" onClick={() => window.location.reload()}>
            Try again
          </button>
        </div>
      </div>
    )
  }

  return <CalendarPage familyId={auth.familyId} displayName={auth.displayName ?? 'Me'} />
}

import { useEffect, useMemo, useState } from 'react'
import { supabase, type FamilyEvent } from '../lib/supabase'
import { useAuth } from '../lib/useAuth'
import { EventModal } from '../components/EventModal'
import {
  MONTHS, WEEKDAYS, monthGrid, sameDay, dayKey, formatTime, formatLongDate,
} from '../lib/dates'

type Props = { familyId: string; displayName: string }

export function CalendarPage({ familyId, displayName }: Props) {
  const auth = useAuth()
  const today = new Date()
  const [cursor, setCursor] = useState(new Date(today.getFullYear(), today.getMonth(), 1))
  const [selected, setSelected] = useState(today)
  const [events, setEvents] = useState<FamilyEvent[]>([])
  const [showModal, setShowModal] = useState(false)
  const [loading, setLoading] = useState(true)

  async function load() {
    setLoading(true)
    const { data } = await supabase
      .from('events')
      .select('*')
      .eq('family_id', familyId)
      .order('start_time')
    setEvents((data as FamilyEvent[]) ?? [])
    setLoading(false)
  }

  useEffect(() => {
    load()
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [familyId])

  const eventsByDay = useMemo(() => {
    const map = new Map<string, FamilyEvent[]>()
    for (const ev of events) {
      const k = dayKey(new Date(ev.start_time))
      const arr = map.get(k) ?? []
      arr.push(ev)
      map.set(k, arr)
    }
    return map
  }, [events])

  const grid = monthGrid(cursor.getFullYear(), cursor.getMonth())
  const selectedEvents = eventsByDay.get(dayKey(selected)) ?? []

  function shiftMonth(delta: number) {
    setCursor(new Date(cursor.getFullYear(), cursor.getMonth() + delta, 1))
  }

  return (
    <div className="app">
      <div className="topbar">
        <div>
          <h1>Family Hub</h1>
          <div className="sub">Hi, {displayName} 👋</div>
        </div>
        <button className="icon-btn" title="Sign out" onClick={() => supabase.auth.signOut()}>⎋</button>
      </div>

      <div className="cal-header">
        <span className="month">{MONTHS[cursor.getMonth()]} {cursor.getFullYear()}</span>
        <div className="cal-nav">
          <button className="icon-btn" onClick={() => shiftMonth(-1)}>‹</button>
          <button className="icon-btn" onClick={() => { const t = new Date(); setCursor(new Date(t.getFullYear(), t.getMonth(), 1)); setSelected(t) }}>•</button>
          <button className="icon-btn" onClick={() => shiftMonth(1)}>›</button>
        </div>
      </div>

      <div className="weekdays">
        {WEEKDAYS.map((d) => <div key={d}>{d}</div>)}
      </div>

      <div className="grid">
        {grid.map((d) => {
          const inMonth = d.getMonth() === cursor.getMonth()
          const dayEvents = eventsByDay.get(dayKey(d)) ?? []
          const classes = ['day']
          if (!inMonth) classes.push('muted')
          if (sameDay(d, today)) classes.push('today')
          if (sameDay(d, selected)) classes.push('selected')
          return (
            <button key={d.toISOString()} className={classes.join(' ')} onClick={() => setSelected(new Date(d))}>
              <span>{d.getDate()}</span>
              <div className="dots">
                {dayEvents.slice(0, 4).map((ev) => (
                  <span key={ev.id} className="dot" style={{ background: ev.color ?? '#ff7043' }} />
                ))}
              </div>
            </button>
          )
        })}
      </div>

      <div className="events">
        <h2>{formatLongDate(selected)}</h2>
        {loading ? (
          <div className="empty">Loading…</div>
        ) : selectedEvents.length === 0 ? (
          <div className="empty">No events. Tap + to add one.</div>
        ) : (
          selectedEvents.map((ev) => (
            <div key={ev.id} className="event-card">
              <div className="event-bar" style={{ background: ev.color ?? '#ff7043' }} />
              <div className="event-info">
                <div className="t">{ev.title}</div>
                <div className="m">
                  {ev.all_day ? 'All day' : formatTime(ev.start_time) + (ev.end_time ? ` – ${formatTime(ev.end_time)}` : '')}
                  {ev.location ? ` · ${ev.location}` : ''}
                </div>
              </div>
            </div>
          ))
        )}
      </div>

      <button className="fab" onClick={() => setShowModal(true)}>+ Add Event</button>

      {showModal && auth.session && (
        <EventModal
          date={selected}
          familyId={familyId}
          userId={auth.session.user.id}
          onClose={() => setShowModal(false)}
          onSaved={() => { setShowModal(false); load() }}
        />
      )}
    </div>
  )
}

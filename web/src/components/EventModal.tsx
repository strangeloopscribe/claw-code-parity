import { useState } from 'react'
import { supabase } from '../lib/supabase'
import { toIso } from '../lib/dates'

type Props = {
  date: Date
  familyId: string
  userId: string
  onClose: () => void
  onSaved: () => void
}

const COLORS = ['#ff7043', '#42a5f5', '#66bb6a', '#ab47bc', '#ffca28', '#26a69a']

export function EventModal({ date, familyId, userId, onClose, onSaved }: Props) {
  const [title, setTitle] = useState('')
  const [allDay, setAllDay] = useState(false)
  const [startTime, setStartTime] = useState('09:00')
  const [endTime, setEndTime] = useState('10:00')
  const [location, setLocation] = useState('')
  const [color, setColor] = useState(COLORS[0])
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState<string | null>(null)

  async function save(e: React.FormEvent) {
    e.preventDefault()
    if (!title.trim()) return
    setBusy(true)
    setError(null)
    try {
      const start = allDay
        ? new Date(date.getFullYear(), date.getMonth(), date.getDate()).toISOString()
        : toIso(date, startTime)
      const end = allDay ? null : toIso(date, endTime)

      const { error } = await supabase.from('events').insert({
        family_id: familyId,
        created_by: userId,
        title: title.trim(),
        location: location.trim() || null,
        start_time: start,
        end_time: end,
        all_day: allDay,
        color,
      })
      if (error) throw error
      onSaved()
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Could not save')
      setBusy(false)
    }
  }

  return (
    <div className="modal-backdrop" onClick={onClose}>
      <form className="modal" onClick={(e) => e.stopPropagation()} onSubmit={save}>
        <h2>New Event</h2>
        {error && <div className="error-msg">{error}</div>}
        <input
          className="field"
          placeholder="What's happening?"
          value={title}
          onChange={(e) => setTitle(e.target.value)}
          autoFocus
          required
        />

        <label style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          <input type="checkbox" checked={allDay} onChange={(e) => setAllDay(e.target.checked)} />
          All day
        </label>

        {!allDay && (
          <div className="modal-row">
            <div>
              <label>Starts</label>
              <input className="field" type="time" value={startTime} onChange={(e) => setStartTime(e.target.value)} style={{ width: '100%' }} />
            </div>
            <div>
              <label>Ends</label>
              <input className="field" type="time" value={endTime} onChange={(e) => setEndTime(e.target.value)} style={{ width: '100%' }} />
            </div>
          </div>
        )}

        <input className="field" placeholder="Location (optional)" value={location} onChange={(e) => setLocation(e.target.value)} />

        <div>
          <label>Color</label>
          <div style={{ display: 'flex', gap: 10, marginTop: 8 }}>
            {COLORS.map((c) => (
              <button
                key={c}
                type="button"
                onClick={() => setColor(c)}
                style={{
                  width: 32, height: 32, borderRadius: '50%', background: c,
                  border: color === c ? '3px solid #2d2a28' : 'none',
                }}
                aria-label={c}
              />
            ))}
          </div>
        </div>

        <div className="btn-row">
          <button type="button" className="btn-ghost" onClick={onClose}>Cancel</button>
          <button type="submit" className="btn-primary" style={{ flex: 1 }} disabled={busy}>
            {busy ? '…' : 'Save'}
          </button>
        </div>
      </form>
    </div>
  )
}

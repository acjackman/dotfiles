import type { EngineInterface, Register, Timer } from 'claude-code'

// idle: nothing pending
// queued: final prompt handed off, its turn not started (a turn already running must not exit)
// armed: exit when the current main-loop turn answers
type Phase = 'idle' | 'queued' | 'armed'

let phase: Phase = 'idle'
let isSubmitted = false
let isBusy = false
let pending: Timer | undefined

const setPhase = ($: EngineInterface, next: Phase) => {
  phase = next
  isSubmitted = false
  pending?.cancel()
  pending = undefined
  $.ui.status(next === 'idle' ? undefined : 'bye: exiting after this turn')
}

// Deferred: $.command.run from inside a hook the session is waiting on is refused
const exit = ($: EngineInterface) => {
  setPhase($, 'idle')
  $.clock.after(0, () => {
    void $.command.run({ command: 'exit', args: '' }).catch(() => {})
  })
}

export const register: Register = on => {
  on('session.start', async ($, e, next) => {
    await $.command.register({
      name: 'bye',
      description: 'Run one last instruction, then exit when its turn ends (bare: exit now / cancel)',
      argumentHint: '[final instructions]',
      immediate: true,
    })

    return next(e)
  })

  on('command.run', { command: 'bye' }, async ($, e) => {
    const text = e.args.trim()

    if (text === '') {
      if (phase !== 'idle') {
        setPhase($, 'idle')
        return { text: 'bye: cancelled' }
      }
      if (!isBusy) {
        exit($)
        return { text: 'bye' }
      }
      setPhase($, 'armed')
      return { text: 'bye: will exit when the current turn ends' }
    }

    setPhase($, 'queued')
    // Submitting from inside the command hook would wait on itself; hand it to a timer
    pending = $.clock.after(0, () => {
      pending = undefined
      isSubmitted = true
      void $.prompt.submit({ text, asUser: true }).catch(() => setPhase($, 'idle'))
    })

    return { text: 'bye: will exit once that is done' }
  })

  on('turn.start', async ($, e, next) => {
    isBusy = true
    if (phase === 'queued' && isSubmitted) phase = 'armed'

    return next(e)
  })

  on('turn.complete', async ($, e, next) => {
    const done = await next(e)
    if (e.agentId !== undefined) return done

    isBusy = false
    if (phase !== 'armed') return done

    // Interrupted, refused or errored turns stay open so you can see what went wrong
    if (e.reason === 'answer') exit($)
    else setPhase($, 'idle')

    return done
  })
}

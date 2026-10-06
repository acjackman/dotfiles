import { expect, mock, test } from 'claude-code/testing'
import type { On } from 'claude-code'
import type { Engine } from 'claude-code/testing'

// Stand-ins for the engine: record /exit runs and prompts the plugin submits
const harness = async ($: Engine, on: On) => {
  const clock = mock.clock(on)
  const exits: string[] = []
  const prompts: string[] = []
  on('command.run', { command: 'exit' }, () => {
    exits.push('exit')
    return { text: '' }
  })
  on('prompt.submit', ($, e) => {
    prompts.push(e.text)
    return { text: e.text }
  })
  on('session.start', ($, e) => ({ cwd: e.cwd }))
  on('command.register', ($, e) => ({ value: { command: e.name } }))
  on('ui.status', () => ({ value: undefined }))
  on('turn.start', ($, e) => ({ turnId: e.turnId }))
  on('turn.complete', ($, e) => ({ text: e.answer }))
  await $.session.start({ cwd: '/', surface: 'terminal', isInteractive: true })
  return { exits, prompts, flush: () => clock.advance(1) }
}

const complete = (turnId: string, reason: 'answer' | 'aborted' = 'answer') => ({
  turnId,
  reason,
  answer: '',
  durationMs: 1,
  isAborted: reason === 'aborted',
})

const bye = (args: string) => ({
  command: 'bye',
  args,
  origin: { kind: 'composer' as const },
  presentation: { isFullscreen: false, columns: 120 },
})

test('/bye <text> while idle submits it, exits after its turn', async ($, on) => {
  const { exits, prompts, flush } = await harness($, on)

  await $.command.run(bye('file the ticket'))
  await flush()
  await flush()
  expect(prompts).toEqual(['file the ticket'])
  expect(exits).toEqual([])

  await $.turn.start({ text: 'file the ticket', turnId: 't-final' })
  await $.turn.complete(complete('t-final'))
  await flush()
  expect(exits).toEqual(['exit'])
})

test('a turn already running when /bye arrives does not exit', async ($, on) => {
  const { exits, flush } = await harness($, on)

  await $.turn.start({ text: 'earlier work', turnId: 't-old' })
  await $.command.run(bye('file the ticket'))
  await flush()
  await $.turn.complete(complete('t-old'))
  await flush()
  expect(exits).toEqual([])

  await $.turn.start({ text: 'file the ticket', turnId: 't-final' })
  await $.turn.complete(complete('t-final'))
  await flush()
  expect(exits).toEqual(['exit'])
})

test('interrupted final turn stays open', async ($, on) => {
  const { exits, flush } = await harness($, on)

  await $.command.run(bye('file the ticket'))
  await flush()
  await $.turn.start({ text: 'file the ticket', turnId: 't-final' })
  await $.turn.complete(complete('t-final', 'aborted'))
  await flush()
  expect(exits).toEqual([])
})

test('subagent turns do not trigger exit', async ($, on) => {
  const { exits, flush } = await harness($, on)

  await $.command.run(bye('file the ticket'))
  await flush()
  await $.turn.start({ text: 'file the ticket', turnId: 't-final' })
  await $.turn.complete({ ...complete('t-sub'), agentId: 'a1' })
  await flush()
  expect(exits).toEqual([])

  await $.turn.complete(complete('t-final'))
  await flush()
  expect(exits).toEqual(['exit'])
})

test('bare /bye exits now when idle, cancels when pending', async ($, on) => {
  const { exits, flush } = await harness($, on)

  await $.command.run(bye('file the ticket'))
  await flush()
  expect((await $.command.run(bye(''))).text).toBe('bye: cancelled')
  await $.turn.start({ text: 'file the ticket', turnId: 't-final' })
  await $.turn.complete(complete('t-final'))
  await flush()
  expect(exits).toEqual([])

  await $.command.run(bye(''))
  await flush()
  expect(exits).toEqual(['exit'])
})

test('bare /bye mid-turn exits when that turn ends', async ($, on) => {
  const { exits, flush } = await harness($, on)

  await $.turn.start({ text: 'work', turnId: 't-1' })
  await $.command.run(bye(''))
  await flush()
  expect(exits).toEqual([])
  await $.turn.complete(complete('t-1'))
  await flush()
  expect(exits).toEqual(['exit'])
})

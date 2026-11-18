import { expect, test } from 'claude-code/testing'
import type { MountTarget } from 'claude-code/testing'

const row = (extra: { model?: string; label?: string; name?: string }): MountTarget<'terminal', 'AgentRow'> => ({
  plugin: 'agent-rows',
  surface: 'terminal',
  component: 'AgentRow',
  requestId: 'a1',
  props: {
    id: 'a1', description: 'scan repo', type: 'Explore', status: 'running', kind: 'local_agent',
    taskStatus: 'running', label: '', startTime: 0, cwd: '/', tokenCount: 0, tokenSamples: [],
    hasRow: true, rowIds: ['a1'], isHidden: false, ...extra,
  },
})

test('shows label and model, falls back to name then type, and leaves model-less rows alone', async ($, on) => {
  const bodies: (string | undefined)[] = []
  on('ui.render', { component: 'AgentRow' }, (_, e, next) => {
    bodies.push(e.props.body)
    return next(e)
  })

  for (const extra of [
    { model: 'claude-opus-5-5', label: 'reading files', name: 'scout' },
    { model: 'claude-haiku-5-5', name: 'scout' },
    { model: 'claude-sonnet-5-5' },
    {},
  ]) await (await $.ui.mount(row(extra))).unmount()

  const plain = bodies.map(b => b?.replace(/\x1b\[[0-9;]*m/g, ''))
  expect(plain).toEqual([
    'reading files · claude-opus-5-5',
    'scout · claude-haiku-5-5',
    'Explore · claude-sonnet-5-5',
    undefined,
  ])
})

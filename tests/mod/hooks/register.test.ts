import type { On } from 'claude-code'
import { expect, mock, test } from 'claude-code/testing'

const SESSION = '/home/.pokepet/sessions/sess-1.json'
const DAY = '/home/.pokepet/jour/2026-10-15/sess-1.json'
const LINK = 'claude://code/continue?session=local_abc'

/**
 * The world under the mod: the engine (which answers the events), an in-memory disk, a clock,
 * variables. By default a Desktop conversation (CLAUDE_CODE_ENTRYPOINT=claude-desktop) that is not
 * on screen: no surface attached, as in Desktop when you look at another conversation.
 */
function world(on: On, options: { entrypoint?: string; brokenWrites?: boolean } = {}) {
  on('turn.start', (_$, e) => ({ turnId: e.turnId }))
  on('turn.complete', () => ({ text: '' }))
  on('session.end', (_$, e) => ({ sessionId: e.sessionId }))
  const disk = new Map<string, string>()
  const writes: { path: string; state?: string }[] = []
  // Calls on $ are answered with { value } (or { deny }, which makes the call fail).
  on('fs.write', (_$, e) => {
    if (options.brokenWrites) return { deny: 'disque plein' }
    disk.set(e.path, e.text)
    writes.push({ path: e.path, state: JSON.parse(e.text).etat })
    return { value: undefined }
  })
  on('fs.exists', (_$, e) => ({ value: disk.has(e.path) }))
  on('fs.read', (_$, e) => ({ value: disk.get(e.path) ?? '' }))
  on('session.id', () => ({ value: 'sess-1' }))
  on('session.surfaces', () => ({ value: [] }))
  // Claude Code's pid: the parent of a `sh` it runs (CLAUDE_PID does not exist in its own environment).
  on('process.run', (_$, e) =>
    e.argv.join(' ') === "/bin/sh -c echo $PPID" ? { value: { exitCode: 0, stdout: '4242\n', stderr: '' } } : { deny: 'inattendu' })
  const entrypoint = options.entrypoint ?? 'claude-desktop'
  mock.env(on, entrypoint === 'claude-desktop'
    ? { HOME: '/home', CLAUDE_CODE_ENTRYPOINT: entrypoint, CLAUDE_CODE_HOST_SESSION_ID: 'local_abc' }
    : { HOME: '/home', CLAUDE_CODE_ENTRYPOINT: entrypoint })
  mock.clock(on, { now: new Date(2026, 9, 15, 16, 2, 11).getTime() })
  const state = () => (disk.has(SESSION) ? JSON.parse(disk.get(SESSION)!) : undefined)
  const writtenStates = () => writes.filter(x => x.path === SESSION).map(x => x.state)
  return { disk, state, writtenStates }
}

const end = (reason: 'answer' | 'aborted' | 'error' | 'refusal', agentId?: string) =>
  ({ answer: '', durationMs: 1, isAborted: reason === 'aborted', turnId: 't1', reason, agentId }) as never

test('un tour qui commence écrit « travaille », avec le pid et le lien Desktop', async ($, on) => {
  const w = world(on)
  await $.turn.start({ text: 'salut', turnId: 't1' })
  expect(w.state()).toEqual({ etat: 'travaille', majLe: expect.any(String), pid: 4242, lien: LINK })
})

test('une réponse finie écrit « fini » et compte une réponse', async ($, on) => {
  const w = world(on)
  await $.turn.start({ text: 'salut', turnId: 't1' })
  await $.turn.complete(end('answer'))
  expect(w.state().etat).toBe('fini')
  expect(w.disk.get(DAY)).toBe('{"reponses":1}')
  await $.turn.start({ text: 'encore', turnId: 't2' })
  await $.turn.complete(end('answer'))
  expect(w.disk.get(DAY)).toBe('{"reponses":2}')
})

test('une interruption finit sans compter', async ($, on) => {
  const w = world(on)
  await $.turn.start({ text: 'salut', turnId: 't1' })
  await $.turn.complete(end('aborted'))
  expect(w.state().etat).toBe('fini')
  expect(w.disk.has(DAY)).toBe(false)
})

test('une erreur écrit « echec »', async ($, on) => {
  const w = world(on)
  await $.turn.start({ text: 'salut', turnId: 't1' })
  await $.turn.complete(end('error'))
  expect(w.state().etat).toBe('echec')
})

test('la fin d’un tour de sous-agent ne change rien', async ($, on) => {
  const w = world(on)
  await $.turn.start({ text: 'salut', turnId: 't1' })
  await $.turn.complete(end('answer', 'agent-1'))
  expect(w.state().etat).toBe('travaille')
  expect(w.disk.has(DAY)).toBe(false)
})

test('une question attend, puis le travail reprend', async ($, on) => {
  const w = world(on)
  on('tool.call', () => ({ deny: 'réponse du test' }))
  await $.turn.start({ text: 'salut', turnId: 't1' })
  await $.tool.call({ tool: 'AskUserQuestion', questions: [] } as never)
  expect(w.writtenStates()).toEqual(['travaille', 'attend', 'travaille'])
})

/** Tool calls that stay running until the test releases them. */
function pendingTools(on: On) {
  const release = new Map<string, () => void>()
  on('tool.call', (_$, e) => new Promise(r => release.set(String(e.tool_use_id), () => r({ deny: 'fin du test' }))))
  return (id: string) => release.get(id)!()
}

/** Gives the mod time to take the call into account (its hooks run on another thread). */
async function letItThrough(_$: unknown) {
  await new Promise(r => setTimeout(r, 50))
}

test('en mode auto, un « ask » tranché sans toi ne fait pas attendre', async ($, on) => {
  const w = world(on)
  on('tool.check', () => ({ decision: 'ask' }))
  await $.turn.start({ text: 'salut', turnId: 't1' })
  await $.tool.check({ tool: 'Bash', input: { command: 'ls' }, tool_use_id: 'u1' })
  expect(w.writtenStates()).toEqual(['travaille'])
})

test('un outil voisin qui finit ne lève pas une question en cours', async ($, on) => {
  const w = world(on)
  const release = pendingTools(on)
  await $.turn.start({ text: 'salut', turnId: 't1' })
  const question = $.tool.call({ tool: 'AskUserQuestion', questions: [], tool_use_id: 'u1' } as never)
  const search = $.tool.call({ tool: 'Grep', pattern: 'x', tool_use_id: 'u2' } as never)
  await letItThrough($)
  expect(w.state().etat).toBe('attend')
  release('u2')
  await search
  expect(w.state().etat).toBe('attend')
  release('u1')
  await question
  expect(w.state().etat).toBe('travaille')
})

test('une question posée par un sous-agent fait aussi attendre, sans compter', async ($, on) => {
  const w = world(on)
  const release = pendingTools(on)
  await $.turn.start({ text: 'salut', turnId: 't1' })
  const question = $.tool.call({ tool: 'AskUserQuestion', questions: [], tool_use_id: 'u3', agentId: 'a1' } as never)
  await letItThrough($)
  expect(w.state().etat).toBe('attend')
  release('u3')
  await question
  expect(w.state().etat).toBe('travaille')
  expect(w.disk.has(DAY)).toBe(false)
})

test('la fermeture écrit « fermee »', async ($, on) => {
  const w = world(on)
  await $.turn.start({ text: 'salut', turnId: 't1' })
  await $.session.end({ reason: 'prompt_input_exit', sessionId: 'sess-1', resume: { id: 'sess-1' } } as never)
  expect(w.state().etat).toBe('fermee')
})

test('une conversation du terminal écrit aussi, sans lien', async ($, on) => {
  const w = world(on, { entrypoint: 'cli' })
  await $.turn.start({ text: 'salut', turnId: 't1' })
  await $.turn.complete(end('answer'))
  expect(w.state()).toEqual({ etat: 'fini', majLe: expect.any(String), pid: 4242 })
  expect(w.disk.get(DAY)).toBe('{"reponses":1}')
})

test('sans interface (claude -p : sdk-cli), rien n’est écrit, même à la fermeture', async ($, on) => {
  const w = world(on, { entrypoint: 'sdk-cli' })
  await $.turn.start({ text: 'salut', turnId: 't1' })
  await $.turn.complete(end('answer'))
  await $.session.end({ reason: 'other', sessionId: 'sess-1', resume: { id: 'sess-1' } } as never)
  expect(w.disk.size).toBe(0)
})

test('une écriture qui échoue ne gêne pas la conversation', async ($, on) => {
  world(on, { brokenWrites: true })
  await expect($.turn.start({ text: 'salut', turnId: 't1' })).resolves.toEqual(expect.anything())
  await expect($.turn.complete(end('answer'))).resolves.toEqual(expect.anything())
})

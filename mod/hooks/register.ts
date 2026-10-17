import type { EngineInterface, Register } from 'claude-code'
import { dayKey } from './day'
import { dayPath, sessionPath } from './paths'
import { counts, desktopLink, endState, INTERACTIVE_ENTRYPOINTS, nextCounter, sessionContent, type State, WAITING_TOOLS } from './state'

// The Claude Code version embedded in the Desktop app (2.1.295) only accepts `$` in functions
// declared in this file, never through an import: everything that touches `$` lives here,
// the neighbouring files only hold pure functions.

// The last state written, to only write changes. Starts over if the mod is reloaded.
let last: State | undefined
// Claude Code's pid, asked once per mod load.
let pid: number | undefined
// The tool calls that wait for your answer (a question, a plan). Several tools can run
// at once: we only go back to « travaille » when none of them is waiting any more.
// Permission dialogs are not tracked: Claude Code does not pass PermissionRequest
// to the plugins you install (log: « bypassed by cc-plugin-sec-default »), and tool.check's
// « ask » also goes to the auto mode classifier, with nobody to ask.
const waiting = new Set<string>()
let callsWithoutId = 0

/**
 * True if the conversation has an interface (Desktop, terminal); false for a `claude -p` (sdk-cli).
 * Reads CLAUDE_CODE_ENTRYPOINT, fixed for the whole process: `$.session.surfaces()` does not fit,
 * in Desktop it is empty as soon as you look at another conversation (checked for real).
 */
async function hasInterface($: EngineInterface): Promise<boolean> {
  return INTERACTIVE_ENTRYPOINTS.includes((await $.env.get('CLAUDE_CODE_ENTRYPOINT')) ?? '')
}

/**
 * The pid of the Claude Code process, which the app watches to clear crashed conversations.
 * CLAUDE_PID only exists in the environment of the commands Claude runs, not in its own:
 * we run a `sh` and read its parent. 0 if that fails.
 */
async function claudePid($: EngineInterface): Promise<number> {
  if (pid === undefined) {
    try {
      const { stdout } = await $.process.run(['/bin/sh', '-c', 'echo $PPID'])
      pid = Number(stdout.trim()) || 0
    } catch {
      pid = 0
    }
  }
  return pid
}

/** Writes `~/.pokepet/sessions/<id>.json`. */
async function writeState($: EngineInterface, state: State): Promise<void> {
  const path = sessionPath(String(await $.env.get('HOME')), await $.session.id())
  const link = desktopLink(await $.env.get('CLAUDE_CODE_HOST_SESSION_ID'))
  await $.fs.write(path, sessionContent(state, await $.clock.now(), await claudePid($), link))
}

/** Adds one response to `~/.pokepet/jour/<date>/<id>.json`. */
async function countOneResponse($: EngineInterface): Promise<void> {
  const path = dayPath(String(await $.env.get('HOME')), dayKey(await $.clock.now()), await $.session.id())
  const current = (await $.fs.exists(path)) ? String(await $.fs.read(path)) : undefined
  await $.fs.write(path, nextCounter(current))
}

/** Writes the state if it changed and if the conversation has an interface; never fails. */
async function record($: EngineInterface, state: State): Promise<void> {
  try {
    if (state === last || !(await hasInterface($))) return
    await writeState($, state)
    last = state
  } catch {
    // Full disk, forbidden directory…: the companion will be wrong, the conversation goes on.
  }
}

/** Adds one response to the daily counter; never fails. */
async function count($: EngineInterface): Promise<void> {
  try {
    if (await hasInterface($)) await countOneResponse($)
  } catch {
    // Same as for record.
  }
}

/**
 * Wires Claude Code's events to the writing of the ~/.pokepet/ files (spec § 4).
 * Every hook always calls `next(e)`: the mod never changes the course of a conversation.
 */
export const register: Register = on => {
  last = undefined
  pid = undefined
  waiting.clear()

  on('turn.start', async ($, e, next) => {
    await record($, 'travaille')
    return next(e)
  })

  // Subagents' calls count too: their questions are asked to you.
  on('tool.call', async ($, e, next) => {
    const id = e.tool_use_id ?? `no-id-${++callsWithoutId}`
    if (WAITING_TOOLS.includes(e.tool)) {
      waiting.add(id)
      await record($, 'attend')
    }
    try {
      return await next(e)
    } finally {
      // The tool gave control back: the question has its answer.
      if (waiting.delete(id) && waiting.size === 0) await record($, 'travaille')
    }
  }).catch(($, e, next) => next(e))

  on('turn.complete', async ($, e, next) => {
    if (e.agentId !== undefined) return next(e)
    waiting.clear()
    await record($, endState(e.reason))
    if (counts(e.reason)) await count($)
    return next(e)
  })

  on('session.end', async ($, e, next) => {
    await record($, 'fermee')
    return next(e)
  })
}

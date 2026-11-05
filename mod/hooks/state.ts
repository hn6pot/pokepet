/**
 * What the mod writes about a conversation (the same vocabulary as SessionState.swift).
 * These values and the file keys below (`etat`, `majLe`, `pid`, `lien`, plus `job` and `terminal`)
 * are the format shared with the installed app: they stay as they are.
 */
export type State = 'travaille' | 'attend' | 'fini' | 'echec' | 'fermee'

/** Why a turn ended, as `turn.complete` says it. */
export type Reason = 'answer' | 'aborted' | 'refusal' | 'error'

/** The CLAUDE_CODE_ENTRYPOINT values that have an interface: the terminal and the Desktop app (not `sdk-cli`, `claude -p`). */
export const INTERACTIVE_ENTRYPOINTS: readonly string[] = ['cli', 'claude-desktop']

/** The tools that wait for your answer: a question, or a plan approval. */
export const WAITING_TOOLS: readonly string[] = ['AskUserQuestion', 'ExitPlanMode']

export function endState(reason: Reason): State {
  return reason === 'error' || reason === 'refusal' ? 'echec' : 'fini'
}

/** Only a response carried through to the end counts for evolution; an interruption does not. */
export function counts(reason: Reason): boolean {
  return reason === 'answer'
}

/** The Desktop link, from CLAUDE_CODE_HOST_SESSION_ID; nothing outside the Desktop app. */
export function desktopLink(hostId: string | undefined): string | undefined {
  return hostId !== undefined && /^local_[A-Za-z0-9-]{1,64}$/.test(hostId)
    ? `claude://code/continue?session=${hostId}`
    : undefined
}

/** The short id of a background job (`claude --bg`), from CLAUDE_JOB_DIR; it ends up in a terminal command, so only this form. */
export function jobId(jobDir: string | undefined): string | undefined {
  const last = jobDir?.replace(/\/+$/, '').split('/').pop()
  return last !== undefined && /^[0-9a-f]{8}$/.test(last) ? last : undefined
}

/** The terminal a conversation runs in, from TERM_PROGRAM; only the two the app knows how to bring forward. */
export function terminalName(termProgram: string | undefined): string | undefined {
  return termProgram === 'iTerm.app' || termProgram === 'Apple_Terminal' ? termProgram : undefined
}

/** Where the conversation can be reached: the Desktop link, the background job, the terminal. All optional. */
export interface Origin {
  link?: string
  job?: string
  terminal?: string
}

/** The content of `sessions/<id>.json`. The time is written without milliseconds: that is what Swift reads. */
export function sessionContent(state: State, ms: number, pid: number, origin: Origin): string {
  const updatedAt = new Date(ms).toISOString().replace(/\.\d{3}Z$/, 'Z')
  return JSON.stringify({
    etat: state,
    majLe: updatedAt,
    pid,
    ...(origin.link === undefined ? {} : { lien: origin.link }),
    ...(origin.job === undefined ? {} : { job: origin.job }),
    ...(origin.terminal === undefined ? {} : { terminal: origin.terminal }),
  })
}

/** The next counter, from the current content of `jour/<date>/<id>.json` (missing or broken: zero). */
export function nextCounter(content: string | undefined): string {
  let responses = 0
  try {
    const parsed = content === undefined ? undefined : JSON.parse(content)
    if (typeof parsed?.reponses === 'number' && parsed.reponses > 0) responses = parsed.reponses
  } catch {
    responses = 0
  }
  return JSON.stringify({ reponses: responses + 1 })
}

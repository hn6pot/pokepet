/**
 * What the mod writes about a conversation (the same vocabulary as SessionState.swift).
 * These values and the file keys below are the format shared with the installed app: they stay in French.
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

/** The content of `sessions/<id>.json`. The time is written without milliseconds: that is what Swift reads. */
export function sessionContent(state: State, ms: number, pid: number, link: string | undefined): string {
  const updatedAt = new Date(ms).toISOString().replace(/\.\d{3}Z$/, 'Z')
  const content = { etat: state, majLe: updatedAt, pid }
  return JSON.stringify(link === undefined ? content : { ...content, lien: link })
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

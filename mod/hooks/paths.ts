/** The files of ~/.pokepet/ (spec § 3), from the home directory. */
export function sessionPath(home: string, id: string): string {
  return `${home}/.pokepet/sessions/${id}.json`
}

/** A conversation's daily counter: only this conversation writes this file. */
export function dayPath(home: string, day: string, id: string): string {
  return `${home}/.pokepet/jour/${day}/${id}.json`
}

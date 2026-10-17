/** The pokepet day starts at 4 a.m., local time: at 3:59 on the 16th, it is still the 15th. */
export const ROLLOVER_HOUR = 4

/** The current day at instant `ms`, written "YYYY-MM-DD" (same rule as PokepetDay.swift). */
export function dayKey(ms: number): string {
  const d = new Date(ms)
  if (d.getHours() < ROLLOVER_HOUR) d.setDate(d.getDate() - 1)
  const two = (n: number) => String(n).padStart(2, '0')
  return `${d.getFullYear()}-${two(d.getMonth() + 1)}-${two(d.getDate())}`
}

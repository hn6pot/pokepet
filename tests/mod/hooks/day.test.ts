import { expect, test } from 'claude-code/testing'
import { dayKey } from '../../../hooks/day'

// Dates are built in local time: the test holds whatever the machine's time zone.
test('avant 4 h, on est encore la veille', () => {
  expect(dayKey(new Date(2026, 9, 16, 3, 59).getTime())).toBe('2026-10-15')
})

test('à 4 h, la journée bascule', () => {
  expect(dayKey(new Date(2026, 9, 16, 4, 0).getTime())).toBe('2026-10-16')
})

test('le soir, c’est le jour même', () => {
  expect(dayKey(new Date(2026, 9, 15, 23, 30).getTime())).toBe('2026-10-15')
})

test('le nouvel an bascule à 4 h', () => {
  expect(dayKey(new Date(2027, 0, 1, 2, 0).getTime())).toBe('2026-12-31')
})

test('le premier du mois avant 4 h revient au dernier jour du mois précédent', () => {
  expect(dayKey(new Date(2026, 2, 1, 1, 0).getTime())).toBe('2026-02-28')
})

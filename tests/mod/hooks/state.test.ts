import { expect, test } from 'claude-code/testing'
import { counts, desktopLink, endState, jobId, nextCounter, sessionContent, terminalName } from '../../../hooks/state'

test('une réponse ou une interruption finit, une erreur ou un refus échoue', () => {
  expect(endState('answer')).toBe('fini')
  expect(endState('aborted')).toBe('fini')
  expect(endState('error')).toBe('echec')
  expect(endState('refusal')).toBe('echec')
})

test('seule une réponse menée à son terme compte', () => {
  expect(counts('answer')).toBe(true)
  expect(counts('aborted')).toBe(false)
  expect(counts('error')).toBe(false)
  expect(counts('refusal')).toBe(false)
})

test('le lien Desktop vient de l’identifiant local_…', () => {
  expect(desktopLink('local_00000000-0000-4000-8000-000000000000')).toBe(
    'claude://code/continue?session=local_00000000-0000-4000-8000-000000000000')
})

test('pas de lien hors Desktop, ni pour un identifiant d’une autre forme', () => {
  expect(desktopLink(undefined)).toBe(undefined)
  expect(desktopLink('00000000-0000-4000-8000-000000000001')).toBe(undefined)
  expect(desktopLink('local_x&autre=1')).toBe(undefined)
})

test('l’identifiant du job vient du dernier segment de CLAUDE_JOB_DIR', () => {
  expect(jobId('/Users/moi/.claude/jobs/c5adc286')).toBe('c5adc286')
  expect(jobId('/Users/moi/.claude/jobs/c5adc286/')).toBe('c5adc286')
})

test('un identifiant de job d’une autre forme n’est pas écrit', () => {
  expect(jobId(undefined)).toBe(undefined)
  expect(jobId('/jobs/C5ADC286')).toBe(undefined)
  expect(jobId('/jobs/../x')).toBe(undefined)
  expect(jobId('/jobs/c5adc286; rm -rf ~')).toBe(undefined)
  expect(jobId('/jobs/c5adc28')).toBe(undefined)
})

test('seuls iTerm et Terminal sont des terminaux connus', () => {
  expect(terminalName('iTerm.app')).toBe('iTerm.app')
  expect(terminalName('Apple_Terminal')).toBe('Apple_Terminal')
  expect(terminalName('vscode')).toBe(undefined)
  expect(terminalName(undefined)).toBe(undefined)
})

test('le contenu est celui que l’app Swift lit (SessionStateTests)', () => {
  const ms = Date.UTC(2026, 9, 15, 14, 2, 11, 456)
  expect(sessionContent('attend', ms, 68387, { link: 'claude://code/continue?session=local_00000000-0000-4000-8000-000000000000' })).toBe(
    '{"etat":"attend","majLe":"2026-10-15T14:02:11Z","pid":68387,"lien":"claude://code/continue?session=local_00000000-0000-4000-8000-000000000000"}')
  expect(sessionContent('attend', Date.UTC(2026, 10, 3, 14, 13, 34), 87344, { job: 'c5adc286' })).toBe(
    '{"etat":"attend","majLe":"2026-11-03T14:13:34Z","pid":87344,"job":"c5adc286"}')
  expect(sessionContent('attend', Date.UTC(2026, 10, 4, 9, 0, 0), 12345, { terminal: 'iTerm.app' })).toBe(
    '{"etat":"attend","majLe":"2026-11-04T09:00:00Z","pid":12345,"terminal":"iTerm.app"}')
})

test('sans origine, aucun champ de plus', () => {
  expect(sessionContent('fini', Date.UTC(2026, 9, 15, 14, 2, 11), 1, {})).toBe(
    '{"etat":"fini","majLe":"2026-10-15T14:02:11Z","pid":1}')
})

test('le compteur part de zéro, s’ajoute, et repart de zéro s’il est cassé', () => {
  expect(nextCounter(undefined)).toBe('{"reponses":1}')
  expect(nextCounter('{"reponses":7}')).toBe('{"reponses":8}')
  expect(nextCounter('{')).toBe('{"reponses":1}')
  expect(nextCounter('{"reponses":-3}')).toBe('{"reponses":1}')
})

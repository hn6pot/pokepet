import { expect, test } from 'claude-code/testing'
import { counts, desktopLink, endState, nextCounter, sessionContent } from '../../../hooks/state'

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

test('le contenu est celui que l’app Swift lit (SessionStateTests)', () => {
  const ms = Date.UTC(2026, 9, 15, 14, 2, 11, 456)
  expect(sessionContent('attend', ms, 68387, 'claude://code/continue?session=local_00000000-0000-4000-8000-000000000000')).toBe(
    '{"etat":"attend","majLe":"2026-10-15T14:02:11Z","pid":68387,"lien":"claude://code/continue?session=local_00000000-0000-4000-8000-000000000000"}')
})

test('sans lien, le champ est absent', () => {
  expect(sessionContent('fini', Date.UTC(2026, 9, 15, 14, 2, 11), 1, undefined)).toBe(
    '{"etat":"fini","majLe":"2026-10-15T14:02:11Z","pid":1}')
})

test('le compteur part de zéro, s’ajoute, et repart de zéro s’il est cassé', () => {
  expect(nextCounter(undefined)).toBe('{"reponses":1}')
  expect(nextCounter('{"reponses":7}')).toBe('{"reponses":8}')
  expect(nextCounter('{')).toBe('{"reponses":1}')
  expect(nextCounter('{"reponses":-3}')).toBe('{"reponses":1}')
})

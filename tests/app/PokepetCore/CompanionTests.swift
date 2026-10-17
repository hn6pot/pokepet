import Foundation
import Testing
@testable import PokepetCore

private let paris: Calendar = {
    var c = Calendar(identifier: .gregorian)
    c.timeZone = TimeZone(identifier: "Europe/Paris")!
    return c
}()
private let t0 = paris.date(from: DateComponents(year: 2026, month: 10, day: 15, hour: 10))!
private let linkA = "claude://code/continue?session=local_aaaa"

private func update(
    _ c: inout Companion, _ display: DisplayState, at seconds: TimeInterval = 0, responses: Int = 0,
    activity: TimeInterval? = 0, link: String? = nil
) -> Appearance {
    c.update(
        now: t0.addingTimeInterval(seconds), urgency: Urgency(display: display, link: link),
        responses: responses, lastActivity: activity.map { t0.addingTimeInterval($0) }, calendar: paris)
}

@Test("chaque état a son animation")
func everyStateHasItsAnimation() {
    var c = Companion(launchDate: t0)
    #expect(update(&c, .resting).base == .idle)
    // No more shaking (Charge): it works and waits calmly; the Rhythm makes it do actions.
    #expect(update(&c, .working).base == .idle)
    #expect(update(&c, .waiting).base == .idle)
    #expect(update(&c, .done).base == .idle)
    #expect(update(&c, .failed).base == .idle)
}

@Test("la bulle et le lien seulement quand une conversation attend")
func bubbleAndLinkOnlyWhenAConversationWaits() {
    var c = Companion(launchDate: t0)
    let waiting = update(&c, .waiting, link: linkA)
    #expect(waiting.bubble && waiting.link == linkA)
    #expect(!update(&c, .working).bubble)
}

@Test("finir fait tourner une fois, échouer fait mal")
func finishingRotatesOnceFailingHurts() {
    var c = Companion(launchDate: t0)
    _ = update(&c, .working)
    #expect(update(&c, .done).interlude == Interlude(movement: .rotate, times: 1))
    #expect(update(&c, .done).interlude == nil)
    _ = update(&c, .working)
    #expect(update(&c, .failed).interlude == Interlude(movement: .hurt, times: 1))
}

@Test("se mettre à attendre fait trois sauts")
func startingToWaitMakesThreeHops() {
    var c = Companion(launchDate: t0)
    _ = update(&c, .working)
    #expect(update(&c, .waiting).interlude == Interlude(movement: .hop, times: 3))
    #expect(update(&c, .waiting).interlude == nil)
}

@Test("au lancement, ni interlude ni flash")
func noInterludeNorFlashAtLaunch() {
    var c = Companion(launchDate: t0)
    let first = update(&c, .done, responses: 40)
    #expect(first.interlude == nil)
    #expect(!first.flash)
    #expect(first.stage == .two)
}

@Test("évoluer déclenche un flash, une fois")
func evolvingFlashesOnce() {
    var c = Companion(launchDate: t0)
    _ = update(&c, .working, responses: 29)
    let evolution = update(&c, .done, responses: 30)
    #expect(evolution.flash && evolution.stage == .two)
    #expect(!update(&c, .done, responses: 30).flash)
}

@Test("un nouveau jour déclenche un flash si le bébé change")
func aNewDayFlashesIfTheBabyChanges() {
    // The two days draw different lineages: it is checked, otherwise the test proves nothing.
    var c = Companion(launchDate: t0)
    var day = t0
    var previousDay = PokepetDay.key(day, calendar: paris)
    repeat {
        previousDay = PokepetDay.key(day, calendar: paris)
        day = day.addingTimeInterval(86_400)
    } while DailyDraw.lineage(for: previousDay) == DailyDraw.lineage(for: PokepetDay.key(day, calendar: paris))
    _ = c.update(now: day.addingTimeInterval(-86_400), urgency: .resting, responses: 0, lastActivity: nil, calendar: paris)
    #expect(c.update(now: day, urgency: .resting, responses: 0, lastActivity: nil, calendar: paris).flash)
}

@Test("il s'endort après 15 minutes sans activité")
func fallsAsleepAfter15MinutesWithoutActivity() {
    var c = Companion(launchDate: t0)
    #expect(update(&c, .resting, at: 900, activity: 0).base == .idle)
    let asleep = update(&c, .resting, at: 901, activity: 0)
    #expect(asleep.base == .sleep)
    #expect(asleep.asleep)
}

@Test("il ne dort pas quand on travaille ou qu'on attend")
func doesNotSleepWhileWorkingOrWaiting() {
    var c = Companion(launchDate: t0)
    #expect(!update(&c, .working, at: 3600, activity: 0).asleep)
    #expect(!update(&c, .waiting, at: 3600, activity: 0).asleep)
}

@Test("au lancement sans activité, il reste éveillé un quart d'heure")
func staysAwakeAQuarterHourAfterLaunchWithoutActivity() {
    var c = Companion(launchDate: t0)
    #expect(update(&c, .resting, at: 600, activity: nil).base == .idle)
    #expect(update(&c, .resting, at: 901, activity: nil).base == .sleep)
}

@Test("l'apparence dit l'état affiché")
func appearanceTellsTheDisplayedState() {
    var c = Companion(launchDate: t0)
    #expect(update(&c, .working).display == .working)
    #expect(update(&c, .waiting).display == .waiting)
}

@Test("un choix du jour remplace le tirage")
func aDailyChoiceReplacesTheDraw() {
    var c = Companion(launchDate: t0)
    let today = PokepetDay.key(t0, calendar: paris)
    let other = DailyDraw.lineage(for: today) == .dragon ? Lineage.ghost : .dragon
    let a = c.update(
        now: t0, urgency: .resting, responses: 0, lastActivity: nil,
        choice: DailyChoice(day: today, lineage: other), calendar: paris)
    #expect(a.lineage == other)
    #expect(a.species == other.species(at: .one))
}

@Test("un choix d'un autre jour est ignoré")
func aChoiceFromAnotherDayIsIgnored() {
    var c = Companion(launchDate: t0)
    let today = PokepetDay.key(t0, calendar: paris)
    let a = c.update(
        now: t0, urgency: .resting, responses: 0, lastActivity: nil,
        choice: DailyChoice(day: "2026-10-01", lineage: .bagon), calendar: paris)
    #expect(a.lineage == DailyDraw.lineage(for: today))
}

@Test("changer de Pokémon déclenche un flash")
func changingPokemonFlashes() {
    var c = Companion(launchDate: t0)
    let today = PokepetDay.key(t0, calendar: paris)
    let drawn = c.update(now: t0, urgency: .resting, responses: 0, lastActivity: nil, calendar: paris)
    let other = DailyDraw.other(than: drawn.lineage, using: &FixedRandom.example)
    let changed = c.update(
        now: t0, urgency: .resting, responses: 0, lastActivity: nil,
        choice: DailyChoice(day: today, lineage: other), calendar: paris)
    #expect(changed.flash)
}

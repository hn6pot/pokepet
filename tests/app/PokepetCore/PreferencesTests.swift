import Foundation
import Testing
@testable import PokepetCore

private func blankPreferences() -> (Preferences, UserDefaults) {
    let name = "pokepet-test-\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: name)!
    defaults.removePersistentDomain(forName: name)
    return (Preferences(defaults: defaults), defaults)
}

@Test("au premier lancement, taille normale et pas de position")
func firstLaunchHasNormalSizeAndNoPosition() {
    let (p, _) = blankPreferences()
    #expect(p.size == 1)
    #expect(p.position == nil)
}

@Test("la taille est bornée", arguments: [(0.29, 0.3), (0.3, 0.3), (1.5, 1.5), (3.0, 3.0), (3.01, 3.0), (-2, 0.3)])
func sizeIsClamped(requested: Double, expected: Double) {
    let (p, _) = blankPreferences()
    p.size = requested
    #expect(p.size == expected)
}

@Test("la position est retenue")
func positionIsRemembered() {
    let (p, _) = blankPreferences()
    p.position = CGPoint(x: 120, y: 48)
    #expect(p.position == CGPoint(x: 120, y: 48))
}

@Test("le choix du jour est retenu")
func dailyChoiceIsRemembered() {
    let (p, _) = blankPreferences()
    #expect(p.dailyChoice == nil)
    p.dailyChoice = DailyChoice(day: "2026-10-17", lineage: .dragon)
    #expect(p.dailyChoice == DailyChoice(day: "2026-10-17", lineage: .dragon))
}

@Test("les réglages déjà enregistrés par l'app installée sont relus")
func preferencesSavedByTheInstalledAppAreReadBack() {
    let (p, defaults) = blankPreferences()
    defaults.set(1.5, forKey: "taille")
    defaults.set([120.0, 48.0], forKey: "position")
    defaults.set("2026-10-17", forKey: "choix.journee")
    defaults.set("spectre", forKey: "choix.lignee")
    #expect(p.size == 1.5)
    #expect(p.position == CGPoint(x: 120, y: 48))
    #expect(p.dailyChoice == DailyChoice(day: "2026-10-17", lineage: .ghost))
}

@Test func theChoiceRemembersItsStartingCount() {
    let (p, _) = blankPreferences()
    p.dailyChoice = DailyChoice(day: "2026-10-17", lineage: .dragon, startResponses: 23)
    #expect(p.dailyChoice?.startResponses == 23)
}

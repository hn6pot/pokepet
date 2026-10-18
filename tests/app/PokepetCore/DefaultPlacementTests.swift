import CoreGraphics
import Testing
@testable import PokepetCore

// A screen whose usable area starts above a 70-point Dock; a 240 × 300 window whose visible sprite
// sits at x 60…180, y 90…210 inside it (bottom-left origin, like AppKit).
private let usable = CGRect(x: 0, y: 70, width: 1440, height: 800)
private let sprite = CGRect(x: 60, y: 90, width: 120, height: 120)

@Test func theSpriteItselfSits40PointsFromTheRightAnd47FromTheBottom() {
    let origin = DefaultPlacement.origin(usableArea: usable, spriteInWindow: sprite)
    #expect(origin.x + sprite.maxX == usable.maxX - 40)
    #expect(origin.y + sprite.minY == usable.minY + 47)
}

@Test func theMarginsCanBeChanged() {
    let origin = DefaultPlacement.origin(usableArea: usable, spriteInWindow: sprite, right: 20, bottom: 10)
    #expect(origin == CGPoint(x: 1440 - 20 - 180, y: 70 + 10 - 90))
}

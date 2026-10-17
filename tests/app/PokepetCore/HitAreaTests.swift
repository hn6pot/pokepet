import CoreGraphics
import Foundation
import Testing
@testable import PokepetCore

/// A 2×2 image where only the top-left pixel is opaque.
private func testImage() -> CGImage {
    let bytes: [UInt8] = [255, 0, 0, 255, 0, 0, 0, 0,
                          0, 0, 0, 0, 0, 0, 0, 0]
    let provider = CGDataProvider(data: Data(bytes) as CFData)!
    return CGImage(
        width: 2, height: 2, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: 8,
        space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
        provider: provider, decode: nil, shouldInterpolate: false, intent: .defaultIntent)!
}

@Test("le cadre visible entoure les pixels opaques")
func visibleBoundsSurroundTheOpaquePixels() {
    #expect(HitArea.visibleBounds(testImage()) == CGRect(x: 0, y: 0, width: 1, height: 1))
}

@Test("une image vide n'a pas de cadre visible")
func anEmptyImageHasNoVisibleBounds() {
    let bytes = [UInt8](repeating: 0, count: 16)
    let empty = CGImage(
        width: 2, height: 2, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: 8,
        space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
        provider: CGDataProvider(data: Data(bytes) as CFData)!, decode: nil, shouldInterpolate: false, intent: .defaultIntent)!
    #expect(HitArea.visibleBounds(empty) == nil)
}

@Test("le cadre visible du vrai Salamèche est plus petit que sa case")
func realCharmandersVisibleBoundsAreSmallerThanItsFrame() throws {
    let idle = try #require(PMDSprites(directory: spritesDirectory).animation(.idle, species: Lineage.fire.allSpecies[0], direction: .front))
    let image = idle.images[0]
    let bounds = try #require(HitArea.visibleBounds(image))
    #expect(bounds.width > 5 && bounds.height > 5)
    #expect(bounds.width < CGFloat(image.width) && bounds.height < CGFloat(image.height))
}

// The « ! » bubble is drawn above the sprite: a click on it must reach it (final review).
@Test("un point dans la bulle est cliquable", arguments: [
    (50.0, 50.0, true), (59.0, 50.0, true), (61.0, 50.0, false), (57.0, 57.0, true), (58.0, 58.0, false),
])
func aPointInTheBubbleIsClickable(x: Double, y: Double, expected: Bool) {
    let bubble = CGRect(x: 40, y: 40, width: 20, height: 20)
    #expect(HitArea.isInCircle(CGPoint(x: x, y: y), frame: bubble) == expected)
}

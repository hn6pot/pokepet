import CoreGraphics
import Foundation
import ImageIO

/// The PMD SpriteCollab source: `<directory>/<number>/AnimData.xml` and the `<name>-Anim.png` sheets.
public final class PMDSprites: SpriteSource {
    private let directory: URL
    private var animData: [String: [String: PMDAnimation]] = [:]
    private var cache: [String: LoadedAnimation] = [:]

    public init(directory: URL) {
        self.directory = directory
    }

    public func animation(_ movement: Movement, species: Species, direction: Direction) -> LoadedAnimation? {
        let key = "\(species.number)/\(movement.rawValue)/\(direction.rawValue)"
        if let cached = cache[key] { return cached }
        guard let pmd = animations(of: species)[movement.rawValue],
              let sheet = loadPNG(directory.appending(path: species.number).appending(path: "\(pmd.sheet)-Anim.png"))
        else { return nil }
        let rows = sheet.height / pmd.height
        // Some animations (Sleep) have a single row: the first one is used.
        let row = direction.rawValue < rows ? direction.rawValue : 0
        let images = (0..<pmd.durations.count).compactMap { column in
            sheet.cropping(to: CGRect(x: column * pmd.width, y: row * pmd.height, width: pmd.width, height: pmd.height))
        }
        guard images.count == pmd.durations.count else { return nil }
        let loaded = LoadedAnimation(images: images, durations: pmd.durations)
        cache[key] = loaded
        return loaded
    }

    private func animations(of species: Species) -> [String: PMDAnimation] {
        if let cached = animData[species.number] { return cached }
        let url = directory.appending(path: species.number).appending(path: "AnimData.xml")
        let parsed = (try? Data(contentsOf: url)).map(AnimData.parse) ?? [:]
        animData[species.number] = parsed
        return parsed
    }

    private func loadPNG(_ url: URL) -> CGImage? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
        return CGImageSourceCreateImageAtIndex(source, 0, nil)
    }
}

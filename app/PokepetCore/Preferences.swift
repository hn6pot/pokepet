import CoreGraphics
import Foundation

/// The position and size remembered from one launch to the next.
/// The `UserDefaults` keys are those of the installed app: they stay as they are.
public final class Preferences {
    public static let minSize = 0.3
    public static let maxSize = 3.0
    /// At 100 %, one sprite pixel is 3 points.
    public static let pointsPerPixel = 3.0

    private let defaults: UserDefaults

    public init(defaults: UserDefaults) {
        self.defaults = defaults
    }

    public static func clamp(_ size: Double) -> Double {
        min(max(size, minSize), maxSize)
    }

    /// 1.0 = 100 %.
    public var size: Double {
        get { defaults.object(forKey: "taille") == nil ? 1 : Self.clamp(defaults.double(forKey: "taille")) }
        set { defaults.set(Self.clamp(newValue), forKey: "taille") }
    }

    /// False once hidden from the menu bar window; shown at first launch.
    public var companionVisible: Bool {
        get { defaults.object(forKey: "compagnon.visible") == nil ? true : defaults.bool(forKey: "compagnon.visible") }
        set { defaults.set(newValue, forKey: "compagnon.visible") }
    }

    /// The lineage picked with « Un autre Pokémon », with its day; `nil` without a choice.
    public var dailyChoice: DailyChoice? {
        get {
            guard let day = defaults.string(forKey: "choix.journee"),
                  let lineage = defaults.string(forKey: "choix.lignee").flatMap(Lineage.init(rawValue:))
            else { return nil }
            return DailyChoice(day: day, lineage: lineage, startResponses: defaults.integer(forKey: "choix.depart"))
        }
        set {
            defaults.set(newValue?.day, forKey: "choix.journee")
            defaults.set(newValue?.lineage.rawValue, forKey: "choix.lignee")
            defaults.set(newValue?.startResponses, forKey: "choix.depart")
        }
    }

    /// The bottom-left corner of the window, in screen coordinates; `nil` at first launch.
    public var position: CGPoint? {
        get {
            guard let xy = defaults.array(forKey: "position") as? [Double], xy.count == 2 else { return nil }
            return CGPoint(x: xy[0], y: xy[1])
        }
        set { defaults.set(newValue.map { [Double($0.x), Double($0.y)] }, forKey: "position") }
    }
}

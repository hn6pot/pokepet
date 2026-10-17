import CoreGraphics

/// What is clickable: the sprite's silhouette (the rectangle of its visible pixels) and the bubble.
/// Clicks go through the empty space around.
public enum HitArea {
    /// The rectangle around the visible pixels, in image pixels, origin at the top left;
    /// `nil` for a fully transparent image.
    public static func visibleBounds(_ image: CGImage) -> CGRect? {
        let width = image.width, height = image.height
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        let drawn = pixels.withUnsafeMutableBytes { bytes -> Bool in
            guard let context = CGContext(
                data: bytes.baseAddress, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4,
                space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
            else { return false }
            context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
            return true
        }
        guard drawn else { return nil }
        // A bitmap context's memory starts with the top row.
        var minX = width, minY = height, maxX = -1, maxY = -1
        for y in 0..<height {
            for x in 0..<width where pixels[(y * width + x) * 4 + 3] > 0 {
                minX = min(minX, x); maxX = max(maxX, x)
                minY = min(minY, y); maxY = max(maxY, y)
            }
        }
        guard maxX >= 0 else { return nil }
        return CGRect(x: minX, y: minY, width: maxX - minX + 1, height: maxY - minY + 1)
    }

    /// True if `point` is in the circle inscribed in `frame` (the « ! » bubble).
    public static func isInCircle(_ point: CGPoint, frame: CGRect) -> Bool {
        let radius = min(frame.width, frame.height) / 2
        let dx = point.x - frame.midX, dy = point.y - frame.midY
        return dx * dx + dy * dy <= radius * radius
    }
}

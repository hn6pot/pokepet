import CoreGraphics

/// Where the pet goes when it has no remembered position: the visible sprite itself (not its larger
/// window) sits 46 points from the right and 42 points from the bottom of the usable screen area
/// (the spot Bérenger picked by hand).
public enum DefaultPlacement {
    public static let rightMargin: CGFloat = 46
    public static let bottomMargin: CGFloat = 42

    /// `usableArea`: the screen's visible frame (without the Dock and menu bar).
    /// `spriteInWindow`: the visible sprite inside the window, bottom-left origin.
    /// Returns the window's bottom-left origin.
    public static func origin(
        usableArea: CGRect, spriteInWindow: CGRect, right: CGFloat = rightMargin, bottom: CGFloat = bottomMargin
    ) -> CGPoint {
        CGPoint(x: usableArea.maxX - right - spriteInWindow.maxX, y: usableArea.minY + bottom - spriteInWindow.minY)
    }
}

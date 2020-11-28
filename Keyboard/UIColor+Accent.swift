import UIKit

/**
 * Adds accent colors and related UI element colors to the global UIColor constants.
 */
extension UIColor {
    /**
     * Returns whether this color is considered "dark". May return nil if the color is
     * in an incompatible color space.
     */
    private func isDark() -> Bool? {
        var white: CGFloat = 0
        if !self.getWhite(&white, alpha: nil) {
            return nil
        }
        return white < 0.5
    }

    /**
     * Returns the user interface style corresponding to this background color.
     */
    private func userInterfaceStyle() -> UIUserInterfaceStyle {
        guard let dark = self.isDark() else { return .unspecified }
        return dark ? .dark : .light
    }

    /**
     * Returns an appropriately themed foreground color for this UI element color when
     * applied on top of the given background color.
     */
    private func aboveBackground(_ color: UIColor) -> UIColor {
        // We're using the "provider" closure as basically a hacky way to be notified
        // that the system theme may have changed. We ignore the input trait collection
        // and instead initialize our own based on the actual background color.
        return UIColor { _ in
            let traits = UITraitCollection(userInterfaceStyle: color.userInterfaceStyle())
            return self.resolvedColor(with: traits)
        }
    }

    /**
     * The app-wide accent color.
     */
    static let accent = UIColor(named: "AccentColor")!

    /**
     * The color for text labels that contain primary content when displayed on top
     * of the app-wide accent color.
     */
    static let accentedLabel = UIColor.label.aboveBackground(accent)
}

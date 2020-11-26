import UIKit

extension UIColor {
    /**
     * Returns an appropriately themed foreground color for this UI element color when
     * applied on top of the given background color.
     */
    private func fromBackgroundColor(_ color: UIColor) -> UIColor {
        // We're using the "provider" closure as basically a hacky way to be notified
        // that the system theme may have changed. We ignore the input trait collection
        // and instead initialize our own based on the immediate background color.
        return UIColor(dynamicProvider: { (_: UITraitCollection) -> UIColor in
            var white: CGFloat = 0
            color.getWhite(&white, alpha: nil)
            let traits: UITraitCollection
            if white < 0.5 {
                traits = UITraitCollection(userInterfaceStyle: .dark)
            } else {
                traits = UITraitCollection(userInterfaceStyle: .light)
            }
            return self.resolvedColor(with: traits)
        })
    }

    /**
     * The app-wide accent color.
     */
    static let accent = UIColor(named: "AccentColor")!

    /**
     * The color for text labels that contain primary content when displayed on top
     * of the app-wide accent color.
     */
    static let accentedLabel = UIColor.label.fromBackgroundColor(accent)
}

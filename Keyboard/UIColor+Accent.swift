import UIKit

/**
 * Adds accent colors and related UI element colors to the global UIColor constants.
 */
extension UIColor {
    /**
     * Applies the inverse gamma transform to the given color component.
     */
    private static func sRGBToLinear(_ value: CGFloat) -> CGFloat {
        if value <= 0.04045 {
            return value / 12.92
        } else {
            return pow((value + 0.055) / 1.055, 2.4)
        }
    }

    /**
     * Returns the relative luminance of this color as defined by WCAG 2.0.
     */
    private func relativeLuminance() -> CGFloat {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        guard self.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else { abort() }
        return 0.2126 * UIColor.sRGBToLinear(red)
             + 0.7152 * UIColor.sRGBToLinear(green)
             + 0.0722 * UIColor.sRGBToLinear(blue)
    }

    /**
     * Computes the contrast ratio between the two given relative luminances.
     * This uses the APCA contrast ratio algorithm, translated from:
     * https://github.com/Myndex/SAPC-APCA/blob/master/JS/APCAsRGBonly.98.js
     */
    private static func apcaContrast(foreground: CGFloat, background: CGFloat) -> CGFloat {
        let scaleBoW: CGFloat = 1.618
        let scaleWoB: CGFloat = 1.618

        let normBGExp: CGFloat = 0.38
        let normTXTExp: CGFloat = 0.43
        let revBGExp: CGFloat = 0.5
        let revTXTExp: CGFloat = 0.43

        let blkThrs: CGFloat = 0.02
        let blkClmp: CGFloat = 1.33

        var Ytxt = foreground
        var Ybg = background
        if Ybg >= Ytxt {
            if Ytxt <= blkThrs {
                Ytxt += pow(abs(Ytxt - blkThrs), blkClmp)
                if Ytxt > Ybg {
                    return 0.0
                }
            }
            return (pow(Ybg, normBGExp) - pow(Ytxt, normTXTExp)) * scaleBoW
        } else {
            if Ybg <= blkThrs {
                Ybg += pow(abs(Ybg - blkThrs), blkClmp)
                if Ybg > Ytxt {
                    return 0.0
                }
            }
            return (pow(Ybg, revBGExp) - pow(Ytxt, revTXTExp)) * scaleWoB
        }
    }

    /**
     * Convenience method for resolving this color with the specified UI theme.
     */
    private func resolvedColor(userInterfaceStyle: UIUserInterfaceStyle) -> UIColor {
        return self.resolvedColor(
            with: UITraitCollection(userInterfaceStyle: userInterfaceStyle)
        )
    }

    /**
     * Returns an appropriately themed foreground color for this UI element color when
     * applied on top of the given background color.
     */
    func contrastingBackground(_ backgroundColor: UIColor) -> UIColor {
        // We're using the "provider" closure as basically a hacky way to be notified
        // that the system theme may have changed. We ignore the input trait collection
        // and instead initialize our own based on the actual background color.
        return UIColor { traits in
            let backgroundLuminance = backgroundColor
                .resolvedColor(with: traits)
                .relativeLuminance()

            let lightColor = self.resolvedColor(userInterfaceStyle: .light)
            let darkColor = self.resolvedColor(userInterfaceStyle: .dark)

            let lightLuminance = lightColor.relativeLuminance()
            let darkLuminance = darkColor.relativeLuminance()

            let lightContrast = abs(
                UIColor.apcaContrast(
                    foreground: lightLuminance,
                    background: backgroundLuminance
                )
            )
            let darkContrast = abs(
                UIColor.apcaContrast(
                    foreground: darkLuminance,
                    background: backgroundLuminance
                )
            )

            if lightContrast < darkContrast {
                return darkColor
            } else {
                return lightColor
            }
        }
    }

    /**
     * The app-wide accent color.
     */
    static let accent = UIColor(named: "AccentColor")!
}

import Foundation

class KeyboardManager {
    private static let bundleIdentifier = "com.crossbowffs.stickerboard.keyboard"

    /**
     * Checks whether the user has enabled our keyboard in settings.
     */
    static func isKeyboardEnabled() -> Bool {
        guard let obj = UserDefaults.standard.object(forKey: "AppleKeyboards") as? NSArray else {
            return true
        }
        return obj.contains(KeyboardManager.bundleIdentifier)
    }
}

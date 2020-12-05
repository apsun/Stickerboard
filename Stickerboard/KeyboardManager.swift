import Foundation

class KeyboardManager {
    private static let bundleIdentifier = "com.crossbowffs.stickerboard.keyboard"

    static let main = KeyboardManager()

    /**
     * Checks whether the user has enabled our keyboard in settings.
     */
    func isKeyboardEnabled() -> Bool {
        guard let obj = UserDefaults.standard.object(forKey: "AppleKeyboards") as? NSArray else {
            return true
        }
        return obj.contains(KeyboardManager.bundleIdentifier)
    }
}

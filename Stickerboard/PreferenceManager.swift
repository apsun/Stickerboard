import Foundation

/**
 * Preference keys.
 */
enum PreferenceKey: String {
    case importStickers = "pref_import_stickers"
    case playground = "pref_playground"
    case signalMode = "pref_signal_mode"
    case tutorial = "pref_tutorial"
    case github = "pref_github"
    case changelog = "pref_changelog"
}

/**
 * Helpers for getting and setting preferences.
 */
class PreferenceManager {
    private static let groupIdentifier = "group.com.crossbowffs.stickerboard.stickers"

    static let main = PreferenceManager()

    private func preferences() -> UserDefaults {
        return UserDefaults(suiteName: PreferenceManager.groupIdentifier)!
    }

    private func bool(key: String) -> Bool? {
        return self.preferences().bool(forKey: key)
    }

    private func setBool(key: String, value: Bool) {
        self.preferences().set(value, forKey: key)
    }

    func signalMode() -> Bool {
        return self.bool(key: PreferenceKey.signalMode.rawValue) ?? false
    }

    func setSignalMode(_ newValue: Bool) {
        self.setBool(key: PreferenceKey.signalMode.rawValue, value: newValue)
    }
}

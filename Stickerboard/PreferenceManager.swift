import Foundation

/**
 * Preference keys.
 */
enum PreferenceKey: String {
    case version = "pref_version"
    case versionCode = "pref_version_code"
    case importStickers = "pref_import_stickers"
    case playground = "pref_playground"
    case signalMode = "pref_signal_mode"
    case tutorial = "pref_tutorial"
    case github = "pref_github"
    case changelog = "pref_changelog"
    case lastStickerPageUrl = "pref_last_sticker_page_url"
}

/**
 * Helpers for getting and setting preferences.
 */
class PreferenceManager {
    static let standard = StandardPreferenceManager()
    static let shared = SharedPreferenceManager()

    private let userDefaults: UserDefaults

    fileprivate init(userDefaults: UserDefaults) {
        self.userDefaults = userDefaults
    }

    fileprivate func bool(key: String) -> Bool? {
        return self.userDefaults.bool(forKey: key)
    }

    fileprivate func setBool(key: String, value: Bool) {
        self.userDefaults.set(value, forKey: key)
    }

    fileprivate func string(key: String) -> String? {
        return self.userDefaults.string(forKey: key)
    }

    fileprivate func setString(key: String, value: String) {
        self.userDefaults.set(value, forKey: key)
    }
}

/**
 * Helper for accessing container-internal preferences.
 */
class StandardPreferenceManager: PreferenceManager {
    init() {
        super.init(userDefaults: UserDefaults.standard)
    }

    func lastStickerPageUrl() -> String? {
        return self.string(key: PreferenceKey.lastStickerPageUrl.rawValue)
    }

    func setLastStickerPageUrl(_ newValue: String) {
        return self.setString(key: PreferenceKey.lastStickerPageUrl.rawValue, value: newValue)
    }
}

/**
 * Helper for accessing preferences that are shared between the app and keyboard
 * extension containers.
 */
class SharedPreferenceManager: PreferenceManager {
    private static let groupIdentifier = "group.com.crossbowffs.stickerboard.stickers"

    init() {
        super.init(userDefaults: UserDefaults(suiteName: SharedPreferenceManager.groupIdentifier)!)
    }

    func signalMode() -> Bool {
        return self.bool(key: PreferenceKey.signalMode.rawValue) ?? false
    }

    func setSignalMode(_ newValue: Bool) {
        self.setBool(key: PreferenceKey.signalMode.rawValue, value: newValue)
    }
}

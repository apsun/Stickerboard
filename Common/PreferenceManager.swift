import Foundation

/**
 * Preference keys.
 */
public enum PreferenceKey: String {
    case versionName = "pref_version_name"
    case versionCode = "pref_version_code"
    case importStickers = "pref_import_stickers"
    case playground = "pref_playground"
    case resizeStickers = "pref_resize_stickers"
    case autoSwitchKeyboard = "pref_auto_switch_keyboard"
    case rememberSelectedPack = "pref_remember_selected_pack"
    case tutorial = "pref_tutorial"
    case github = "pref_github"
    case changelog = "pref_changelog"
    case lastStickerPageUrl = "pref_last_sticker_page_url"
}

/**
 * Helpers for getting and setting preferences.
 */
public class PreferenceManager {
    public static let standard = StandardPreferenceManager()
    public static let shared = SharedPreferenceManager()

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
public class StandardPreferenceManager: PreferenceManager {
    fileprivate init() {
        super.init(userDefaults: UserDefaults.standard)
    }

    public func lastStickerPageUrl() -> String? {
        return self.string(key: PreferenceKey.lastStickerPageUrl.rawValue)
    }

    public func setLastStickerPageUrl(_ newValue: String) {
        return self.setString(key: PreferenceKey.lastStickerPageUrl.rawValue, value: newValue)
    }
}

/**
 * Helper for accessing preferences that are shared between the app and keyboard
 * extension containers.
 */
public class SharedPreferenceManager: PreferenceManager {
    private static let groupIdentifier = "group.com.crossbowffs.stickerboard.stickers"

    fileprivate init() {
        super.init(userDefaults: UserDefaults(suiteName: SharedPreferenceManager.groupIdentifier)!)
    }

    public func resizeStickers() -> Bool {
        return self.bool(key: PreferenceKey.resizeStickers.rawValue) ?? false
    }

    public func setResizeStickers(_ newValue: Bool) {
        self.setBool(key: PreferenceKey.resizeStickers.rawValue, value: newValue)
    }

    public func autoSwitchKeyboard() -> Bool {
        return self.bool(key: PreferenceKey.autoSwitchKeyboard.rawValue) ?? false
    }

    public func setAutoSwitchKeyboard(_ newValue: Bool) {
        self.setBool(key: PreferenceKey.autoSwitchKeyboard.rawValue, value: newValue)
    }

    public func rememberSelectedPack() -> Bool {
        return self.bool(key: PreferenceKey.rememberSelectedPack.rawValue) ?? false
    }

    public func setRememberSelectedPack(_ newValue: Bool) {
        self.setBool(key: PreferenceKey.rememberSelectedPack.rawValue, value: newValue)
    }
}

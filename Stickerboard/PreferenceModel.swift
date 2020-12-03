/**
 * Denotes the type of the preference cell you want.
 */
enum PreferenceType {
    /**
     * A cell with a clickable button.
     */
    case button(label: String)

    /**
     * A cell with an on/off switch.
     */
    case `switch`(label: String)

    /**
     * A cell with a StickerTextView.
     */
    case stickerTextView
}

/**
 * Represents a single preference cell.
 */
struct Preference {
    let id: String
    let type: PreferenceType
}

/**
 * Represents a group of preference cells, with an optional header and footer.
 */
struct PreferenceSection {
    let header: String?
    let footer: String?
    let preferences: [Preference]
}

/**
 * Represents the root of your preference tree.
 */
struct PreferenceRoot {
    let sections: [PreferenceSection]
}

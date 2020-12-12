import Foundation

/**
 * Returns a localized string for the given key.
 */
public func L(_ key: String) -> String {
    return NSLocalizedString(key, comment: "")
}

/**
 * Returns a formatted localized string for the given key.
 */
public func F(_ key: String, _ args: CVarArg...) -> String {
    return String(format: L(key), locale: .current, arguments: args)
}

import Foundation

/**
 * An error with a message.
 */
class RuntimeError: LocalizedError {
    private let message: String

    init(_ message: String) {
        self.message = message
    }

    var errorDescription: String? {
        return self.message
    }
}

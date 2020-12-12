import Foundation

/**
 * An error with a message.
 */
public class RuntimeError: LocalizedError {
    private let message: String

    public init(_ message: String) {
        self.message = message
    }

    public var errorDescription: String? {
        return self.message
    }
}

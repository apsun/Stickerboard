import Foundation

/**
 * Wrapper around NSCache that works with Hashable objects.
 */
class Cache<Key: Hashable, Value> {
    private class KeyWrapper: NSObject {
        let key: Key

        init(_ key: Key) {
            self.key = key
        }

        override var hash: Int {
            return self.key.hashValue
        }

        override func isEqual(_ object: Any?) -> Bool {
            guard let other = object as? KeyWrapper else { return false }
            return self.key == other.key
        }
    }

    private class ValueWrapper {
        let value: Value

        init(_ value: Value) {
            self.value = value
        }
    }

    private let inner = NSCache<KeyWrapper, ValueWrapper>()

    subscript(key: Key) -> Value? {
        get {
            return self.inner.object(forKey: KeyWrapper(key))?.value
        }
        set {
            if let newValue = newValue {
                self.inner.setObject(ValueWrapper(newValue), forKey: KeyWrapper(key))
            } else {
                self.inner.removeObject(forKey: KeyWrapper(key))
            }
        }
    }
}

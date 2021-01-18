import Foundation

/// A property wrapper that ensures atomic access to a value. IE only one thing can write at a time.
/// Multiple things can potentially read at the same time, just not during a write.
/// By using `pthread` to do the locking, this safer then using a `DispatchQueue/barrier` as there isn't a chance
/// of priority inversion.
@propertyWrapper
final class Atomic<Value> {

    private var value: Value
    private let lock: Lock = PThreadRWLock()

    init(wrappedValue value: Value) {
        self.value = value
    }

    var wrappedValue: Value {
        get {
            self.lock.readLock()
            defer { self.lock.unlock() }
            return self.value
        }
        set {
            self.lock.writeLock()
            self.value = newValue
            self.lock.unlock()
        }
    }

    /// Provides an closure that will be called synchronously. This closure will be passed in the current value
    /// and it is free to modify it. Any modifications will be saved back to the original value.
    /// No other reads/writes will be allowed between when the closure is called and it returns.
    func mutate(_ closure: (inout Value) -> Void) {
        self.lock.writeLock()
        closure(&value)
        self.lock.unlock()
    }
}

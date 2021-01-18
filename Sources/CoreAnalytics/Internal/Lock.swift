import Foundation

/// Defines a basic signature that all locks will conform to. Provides the basis for atomic access to stuff.
protocol Lock {
    init()
    /// Lock a resource for writing. So only one thing can write, and nothing else can read or write.
    func writeLock()
    /// Lock a resource for reading. Other things can also lock for reading at the same time, but nothing else can write at that time.
    func readLock()
    /// Unlock a resource
    func unlock()
}

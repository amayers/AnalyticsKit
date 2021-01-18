import Foundation

final class PThreadRWLock: Lock {
    private var rwLock = pthread_rwlock_t()

    init() {
        guard pthread_rwlock_init(&rwLock, nil) == 0 else {
            preconditionFailure("Unable to initialize the lock")
        }
    }

    deinit {
        pthread_rwlock_destroy(&rwLock)
    }

    func writeLock() {
        pthread_rwlock_wrlock(&rwLock)
    }

    func readLock() {
        pthread_rwlock_rdlock(&rwLock)
    }

    func unlock() {
        pthread_rwlock_unlock(&rwLock)
    }
}

import Foundation

extension Array where Element == SendingDelayedAnalyticsEvent {
    func oldestFirst() -> Self {
        sorted { lhs, rhs in
            lhs.timeEventOccurred < rhs.timeEventOccurred
        }
    }
    func shouldSendQueuedEvents() -> Bool {
        return if count >= 10 {
            true
        } else {
            (oldestFirst().first?.timeEventOccurred.timeIntervalSinceNow ?? 0) <= -300
        }
    }
    
    mutating func popEvents(batchSize: Int) -> ArraySlice<Element> {
        let range = 0..<Swift.min(count, batchSize)
        guard !range.isEmpty else {
            return []
        }
        let events = self[range]
        for index in range.sorted(by: >) {
            remove(at: index)
        }
        return events
    }
}

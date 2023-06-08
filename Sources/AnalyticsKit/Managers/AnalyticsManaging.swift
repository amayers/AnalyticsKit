import Foundation

public protocol AnalyticsManaging {
    var hasUserApprovedAnalytics: Bool { get set }
    
    /// Logs an event on all enabled services. Waits for the event to be sent (if the event queue is ready to be sent).
    func logCustomEvent(_ event: AnalyticsEvent) async
}

public extension AnalyticsManaging {
    /// Logs an event on all enabled services. Does not wait for the event to be sent.
    func logCustomEvent(_ event: AnalyticsEvent) {
        Task {
            await logCustomEvent(event)
        }
    }
}

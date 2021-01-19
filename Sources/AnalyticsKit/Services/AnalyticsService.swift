import Foundation

public protocol AnalyticsService {

    /// Enables/disables all analytics tracking.
    func set(enabled: Bool)

    /// Record that all actions from now on are linked to this specific userID.
    func configure(userID: UUID)

    /// Logs an event.
    func logCustomEvent(_ event: AnalyticsEvent)
}

import Foundation

public protocol Service {
    /// How many items the service can send at a time.
    var batchSize: Int { get }

    func send<Events: Collection>(
        events: Events,
        for userID: UUID
    ) async throws where Events.Element == SendingDelayedAnalyticsEvent
}

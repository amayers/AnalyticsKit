import Foundation

/// Wrapper around an `AnalyticsEvent` that records the time that the event was originally fired & the event.
public struct SendingDelayedAnalyticsEvent: Sendable {
    let event: AnalyticsEvent
    /// The original time the event happened.
    let timeEventOccurred: Date
}

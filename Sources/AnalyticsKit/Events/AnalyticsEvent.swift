import Foundation

/// Base protocol for anything that you want to log as a discrete event.
/// If you are creating an event for the user changing app settings, you would probably want to do something like the following:
/// `name = "settings_changed"`
/// `attributes = ["use_metric_units" : settings.useMetric, "sound_effects_enabled" : settings.soundEnabled]`
public protocol AnalyticsEvent {
    /// The name that will be shown in your analytics service for this event.
    /// You should keep this name fixed, and not change its values all the time.
    var name: String { get }

    /// Key value pairs of attributes for this event. The values' types are limited based on the analytics service(s) you will use them with.
    /// For example `MixpanelAnalyticsService` supports `String`, `Int`, `Double`, `Bool`.
    var attributes: [String: Any]? { get }

    /// This method will be called by the analytics manager when the event was sent. Use this to do any work needed to finalize the event.
    /// Using this prevents having to do things like recording a unique event on the event's init. That way the `init` doesn't modify state.
    /// It may be called on any queue.
    func wasSent()
}

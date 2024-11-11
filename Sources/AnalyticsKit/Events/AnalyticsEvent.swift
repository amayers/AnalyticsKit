import Foundation

/// Base protocol for anything that you want to log as a discrete event.
/// If you are creating an event for the user changing app settings, you would probably want to do something like the following:
/// `name = "settings_changed"`
/// `attributes = ["use_metric_units" : settings.useMetric, "sound_effects_enabled" : settings.soundEnabled]`
public protocol AnalyticsEvent: Sendable {
    /// The name that will be shown in your analytics service for this event.
    /// You should keep this name fixed, and not change its values all the time.
    var name: String { get }

    /// Key value pairs of attributes for this event. The values' types are limited based on the analytics service(s) you will use them with.
    /// For example `MixpanelAnalyticsService` supports `String`, `Int`, `Double`, `Bool`.
    var attributes: [String: AnalyticsEventAttribute]? { get }
    
    /// Should the `standardAttributes` (device model, app & OS versions) be sent in addition to the `attributes`? Defaults to `true`
    var shouldSendStandardAttributes: Bool { get }

    /// This method will be called by the analytics manager when the event was sent. Use this to do any work needed to finalize the event.
    /// Using this prevents having to do things like recording a unique event on the event's init. That way the `init` doesn't modify state.
    /// It may be called on any queue.
    func wasSent()
}

public extension AnalyticsEvent {
    var shouldSendStandardAttributes: Bool { true }
    
    /// Things like OS version, app version, device model that should be attached to every type of analytics event.
    @MainActor
    var standardAttributes: [String: Sendable] {
        let appInfo = AppInfo()
        let deviceInfo = DeviceInfo()
        let locale = Locale.current
        return [
            "ios_version": deviceInfo.osVersion,
            "app_version": appInfo.version,
            "app_build": appInfo.build,
            "device_model": deviceInfo.deviceModelIdentifier,
            "language_code": locale.language.languageCode?.identifier ?? "unknown",
            "region_code": locale.region?.identifier ?? "unknown",
            "locale_identifier": locale.identifier
        ]
    }
}

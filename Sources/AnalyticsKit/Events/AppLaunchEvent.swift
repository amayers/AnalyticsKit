import Foundation

/// This event should be sent every time the app is launched. It identifies the OS version, app version, device model info, and locale details
public struct AppLaunchEvent: AnalyticsEvent {
    public let name = "app_launch"

    public let attributes: [String: Any]? = nil

    public init() { }

    public func wasSent() { }
}

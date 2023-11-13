import Foundation

/// This event should be sent every time the app is launched. It identifies the OS version, app version, device model info, and locale details
public struct AppLaunchEvent: AnalyticsEvent {
    public let name = "app_launch"

    public let attributes: [String: AnalyticsEventAttribute]?

    /// - Parameter attributes: By default a bunch of standard device & app attributes will be sent. If you have
    /// any additional attributes, add them here.
    public init(attributes: [String: AnalyticsEventAttribute] = [:]) {
        self.attributes = attributes
    }

    public func wasSent() { }
}

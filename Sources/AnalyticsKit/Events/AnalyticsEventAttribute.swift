import Foundation

/// Used to limit attributes to ones supported by the manager.
public protocol AnalyticsEventAttribute: Sendable {
    
}

// MARK: - Supported attribute types

extension Int: AnalyticsEventAttribute { }
extension Double: AnalyticsEventAttribute { }
extension Bool: AnalyticsEventAttribute { }
extension String: AnalyticsEventAttribute { }

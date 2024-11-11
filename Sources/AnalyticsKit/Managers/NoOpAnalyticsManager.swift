import Foundation
import OSLog

/// A manager that doesn't do anything. Useful for when you want to test types that take a `AnalyticsManaging`
/// and you don't want to build a real manager
public actor NoOpAnalyticsManager: AnalyticsManaging {
    private let logger: Logger
    
    public init() {
        logger = Logger.analyticsLogger(category: String(describing: Self.self))
    }
    
    public func logCustomEvent(_ event: AnalyticsEvent) async {
        logger.debug("Event \(event.name) logging simulated")
    }
}

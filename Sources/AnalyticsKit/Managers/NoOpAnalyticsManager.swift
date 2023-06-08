import Foundation
import OSLog

/// A manager that doesn't do anything. Useful for when you want to test types that take a `AnalyticsManaging`
/// and you don't want to build a real manager
public final class NoOpAnalyticsManager: AnalyticsManaging {
    private let logger: Logger
    
    public var hasUserApprovedAnalytics: Bool = false {
        didSet {
            logger.debug("hasUserApprovedAnalytics changed to \(self.hasUserApprovedAnalytics)")
        }
    }
    
    public init() {
        logger = Logger.analyticsLogger(category: String(describing: Self.self))
    }
    
    public func logCustomEvent(_ event: AnalyticsEvent) async {
        logger.debug("Event \(event.name) logging simulated")
    }
}

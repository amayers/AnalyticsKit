import Foundation

public final class AnalyticsManager {
    private enum Constants {
        static let hasUserApprovedAnalyticsKey = "AnalyticsManager_hasUserApprovedAnalytics"
    }

    public static var shared: AnalyticsManager = AnalyticsManager()

    private var services: [AnalyticsService] = []
    private let queue = DispatchQueue(label: "com.AnalyticsManager", qos: .utility, autoreleaseFrequency: .workItem, target: .global(qos: .utility))

    /// The global switch that toggles analytics tracking. Defaults to `true`
    public var hasUserApprovedAnalytics: Bool {
        didSet {
            dispatchPrecondition(condition: .onQueue(.main))
            UserDefaults.standard.set(hasUserApprovedAnalytics, forKey: Constants.hasUserApprovedAnalyticsKey)
            if hasUserApprovedAnalytics {
                queue.async {
                    self.services.forEach({ (service) in
                        service.set(enabled: self.hasUserApprovedAnalytics)
                        service.configure(userID: UserIdentifier.identifierForVendor())
                    })
                }
            }
        }
    }

    private init() {
        // This sets the default of `hasUserApprovedAnalytics` to `true`, but once a user toggles the setting manually, this value is overwritten.
        UserDefaults.standard.register(defaults: [Constants.hasUserApprovedAnalyticsKey: true])
        self.hasUserApprovedAnalytics = UserDefaults.standard.bool(forKey: Constants.hasUserApprovedAnalyticsKey)
    }

    /// Adds a new `AnalyticsService` that will be used when logging events. You can add as many services as you like and they will all get used.
    public func add(service: AnalyticsService) {
        queue.async {
            service.set(enabled: self.hasUserApprovedAnalytics)
            if self.hasUserApprovedAnalytics {
                service.configure(userID: UserIdentifier.identifierForVendor())
            }
            self.services.append(service)
        }
    }

    /// Logs an event on all enabled services
    public func logCustomEvent(_ event: AnalyticsEvent) {
        guard hasUserApprovedAnalytics else { return }
        queue.async {
            self.services.forEach { (service) in
                service.logCustomEvent(event)
            }
            event.wasSent()
        }
    }
}

import OSLog
import UIKit

public final class AnalyticsManager {
    private enum Constants {
        static let hasUserApprovedAnalyticsKey = "AnalyticsManager_hasUserApprovedAnalytics"
    }
    
    private let logger: Logger
    private let service: Service
    private let userDefaults: UserDefaults
    
    private let queue: EventQueue
    
    public var hasUserApprovedAnalytics: Bool {
        didSet {
            userDefaults.set(
                hasUserApprovedAnalytics,
                forKey: Constants.hasUserApprovedAnalyticsKey
            )
        }
    }

    public init(
        service: Service,
        queue: EventQueue = .init(),
        userDefaults: UserDefaults = .standard
    ) {
        self.logger = Logger.analyticsLogger(category: String(describing: Self.self))
        self.service = service
        self.queue = queue
        self.userDefaults = userDefaults
        // This sets the default of `hasUserApprovedAnalytics` to `true`, but once a user toggles the setting manually, this value is overwritten.
        userDefaults.register(defaults: [Constants.hasUserApprovedAnalyticsKey: true])
        hasUserApprovedAnalytics = userDefaults.bool(forKey: Constants.hasUserApprovedAnalyticsKey)
        
        Task { @MainActor in
            // The following app events should all trigger sending any queued events, since after these events our app might stop running,
            // and we'd loose the events.
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(forceSendingAllEvents),
                name: UIApplication.didReceiveMemoryWarningNotification,
                object: nil
            )
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(forceSendingAllEvents),
                name: UIApplication.didEnterBackgroundNotification,
                object: nil
            )
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(forceSendingAllEvents),
                name: UIApplication.willResignActiveNotification,
                object: nil
            )
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(forceSendingAllEvents),
                name: UIApplication.willTerminateNotification,
                object: nil
            )
        }
    }
    
    /// Logs an event on all enabled services. Does not wait for the event to be sent.
    public func logCustomEvent(_ event: AnalyticsEvent) {
        Task {
            await logCustomEvent(event)
        }
    }
    
    /// Logs an event on all enabled services. Waits for the event to be sent (if the event queue is ready to be sent).
    public func logCustomEvent(_ event: AnalyticsEvent) async {
        logger.info("Event \(event.name) attributes: \(event.attributes?.description ?? "") added to the queue")
        await queue.add(
            event: SendingDelayedAnalyticsEvent(
                event: event,
                timeEventOccurred: Date()
            )
        )
        await sendQueuedEventsWhenNecessary()
    }
    
    // MARK: - Private Methods
    
    @objc nonisolated private func forceSendingAllEvents() {
        Task {
            logger.info("Force sending all events started")
            while await !queue.events.isEmpty {
                await sendBatchOfEvents()
            }
            logger.info("Force sending all events completed")
        }
    }
    
    private func sendQueuedEventsWhenNecessary() async {
        logger.info("Sending queued events when necessary started")
        while await queue.events.shouldSendQueuedEvents() {
            await sendBatchOfEvents()
        }
        logger.info("Sending queued events when necessary completed")
    }
    
    private func sendBatchOfEvents() async {
        let events = await queue.pop(batchSize: service.batchSize)
        logger.info("Sending \(events.count) events started")
        do {
            try await service.send(events: events, for: UserIdentifier.identifierForVendor())
            events.forEach {
                logger.info("Event: \($0.event.name) was sent.")
                $0.event.wasSent()
            }
            logger.info("Sending \(events.count) events completed")
        } catch {
            let eventNames = events.map { $0.event.name }
            logger.error("Sending \(eventNames) failed with error \(error). Reenqueuing those events.")
            await queue.reenqueue(events: events)
        }
    }
}

// MARK: - EventQueue

public actor EventQueue {
    private(set) var events: [SendingDelayedAnalyticsEvent] = []
    
    public init() { }
    
    func add(event: SendingDelayedAnalyticsEvent) {
        events.append(event)
    }
    
    func pop(batchSize: Int) -> ArraySlice<SendingDelayedAnalyticsEvent> {
        events.popEvents(batchSize: batchSize)
    }
    
    func reenqueue(events: any Collection<SendingDelayedAnalyticsEvent>) {
        self.events.append(contentsOf: events)
    }
}

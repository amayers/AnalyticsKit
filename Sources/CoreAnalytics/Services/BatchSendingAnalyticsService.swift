import UIKit

/// Base class for an analytics service that batches up events and sends them once certain conditions have been met.
/// You must subclass this to actually implement sending.
public class BatchSendingAnalyticsService {

    // MARK: - Properties

    @Atomic
    fileprivate(set) var queuedEvents: [SendingDelayedAnalyticsEvent] = []
    @Atomic
    fileprivate(set) var trackingEnabled: Bool = false
    fileprivate(set) var userID: UUID?

    /// The maximum number of events that will be passed to the `send(events:)` function at a time.
    public let sendBatchSize: Int

    // MARK: - Things subclasses can override

    /// Create the service. This also registers the service to be notified by the system about app lifecycle events.
    /// Those will be used to trigger sending all queued events, so those events aren't lost when an app quits.
    /// - Parameter sendBatchSize: The maximum number of events that will be passed to the `send(events:)` function at a time.
    init(sendBatchSize: Int) {
        self.sendBatchSize = sendBatchSize

        // The following app events should all trigger sending any queued events, since after these events our app might stop running,
        // and we'd loose the events.
        NotificationCenter.default.addObserver(self, selector: #selector(forceSendingAllEvents),
                                               name: UIApplication.didReceiveMemoryWarningNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(forceSendingAllEvents),
                                               name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(forceSendingAllEvents),
                                               name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(forceSendingAllEvents),
                                               name: UIApplication.willTerminateNotification, object: nil)
    }

    /// Subclasses can override this to decide their own rules around when to send events.
    /// By default it is checked every time a new event is logged, but you are free to check it at other times and then call `sendQueuedEvents()`
    /// whenever it makes sense for your service subclass.
    func shouldSendQueuedEvents() -> Bool {
        return self.queuedEvents.count >= 10
    }

    /// Subclasses must override this to do the actual sending/saving of events. If an event fails to send/save then pass them to `sendingFailed(for:)`.
    func send<Events: Collection>(events: Events) where Events.Element == SendingDelayedAnalyticsEvent {
        fatalError("Subclass needs to override this method to do all sending. Do NOT call super inside it.")
    }

    // MARK: - Final methods

    /// Sending these events failed, so add them back to the queue, and send them again later.
    final func sendingFailed<Events: Collection>(for events: Events) where Events.Element == SendingDelayedAnalyticsEvent {
        self.queuedEvents.append(contentsOf: events)
    }

    private func sendBatchOfEvents() {
        var events: [SendingDelayedAnalyticsEvent] = []
        _queuedEvents.mutate { (queuedEvents) in
            let range = 0..<min(queuedEvents.count, self.sendBatchSize)
            guard !range.isEmpty else { return }
            events.append(contentsOf: queuedEvents[range])
            for index in range.sorted(by: >) {
                queuedEvents.remove(at: index)
            }
        }
        send(events: events)
    }

    final func sendQueuedEvents() {
        while shouldSendQueuedEvents() {
            sendBatchOfEvents()
        }
    }

    @objc
    final func forceSendingAllEvents() {
        while !self.queuedEvents.isEmpty {
            sendBatchOfEvents()
        }
    }
}

// MARK: - AnalyticsService

extension BatchSendingAnalyticsService: AnalyticsService {
    public final func set(enabled: Bool) {
        self.trackingEnabled = enabled
    }

    public final func configure(userID: UUID) {
        self.userID = userID
    }

    public final func logCustomEvent(_ event: AnalyticsEvent) {
        guard self.trackingEnabled else { return }
        self.queuedEvents.append(SendingDelayedAnalyticsEvent(event: event, timeEventOccurred: Date()))
        if shouldSendQueuedEvents() {
            sendQueuedEvents()
        }
    }
}

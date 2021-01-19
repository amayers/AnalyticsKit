@testable import AnalyticsKit
import XCTest

final class BatchSendingAnalyticsServiceTests: XCTestCase {

    private func send(events: Int, using service: TestBatchService) {
        (0..<events).forEach { (_) in
            service.logCustomEvent(MockEvent())
        }
    }

    func testNotSendingUntilBatchSizeHit() {
        let service = TestBatchService(maxQueueSizeTriggeringSending: 3, sendCalled: { (_, _) in
            XCTFail("We didn't log enough items, so we should never have been sent")
        })
        let eventCountLogged = 2
        send(events: eventCountLogged, using: service)
        XCTAssertEqual(service.queuedEvents.count, eventCountLogged)
    }

    func testSendingOnceBatchSizeHit() {
        var numberOfEventsSent = 0
        let service = TestBatchService(maxQueueSizeTriggeringSending: 4, sendCalled: { (events, service) in
            XCTAssertEqual(events.count, service.sendBatchSize)
            numberOfEventsSent += events.count
        })
        let eventCountLogged = 4
        send(events: eventCountLogged, using: service)

        XCTAssertEqual(numberOfEventsSent, service.sendBatchSize)
        XCTAssertEqual(service.maxQueueSizeTriggeringSending - numberOfEventsSent, service.queuedEvents.count)
    }

    func testForceSendingAll() {
        var numberOfEventsSent = 0
        let service = TestBatchService(maxQueueSizeTriggeringSending: 10, sendCalled: { (events, service) in
            XCTAssertEqual(events.count, service.sendBatchSize)
            numberOfEventsSent += events.count
        })
        let eventCountLogged = 4
        send(events: eventCountLogged, using: service)
        XCTAssertEqual(numberOfEventsSent, 0)
        service.forceSendingAllEvents()
        XCTAssertEqual(numberOfEventsSent, eventCountLogged)
        XCTAssert(service.queuedEvents.isEmpty)
    }

    func testSendingFailure() {
        var numberOfEventsSent = 0
        var hasFailed = false
        let service = TestBatchService(maxQueueSizeTriggeringSending: 10, sendCalled: { (events, service) in
            XCTAssertEqual(events.count, service.sendBatchSize)
            if hasFailed {
                numberOfEventsSent += events.count
            } else {
                service.sendingFailed(for: events)
                hasFailed = true
            }
        })
        let eventCountLogged = 4
        send(events: eventCountLogged, using: service)
        XCTAssertEqual(numberOfEventsSent, 0)
        XCTAssertFalse(hasFailed)
        service.forceSendingAllEvents()
        XCTAssert(hasFailed)
        XCTAssertEqual(numberOfEventsSent, eventCountLogged)
        XCTAssert(service.queuedEvents.isEmpty)
    }
}

private class TestBatchService: BatchSendingAnalyticsService {
    let sendCalled: ([SendingDelayedAnalyticsEvent], TestBatchService) -> Void
    let maxQueueSizeTriggeringSending: Int

    init(maxQueueSizeTriggeringSending: Int, sendCalled: @escaping ([SendingDelayedAnalyticsEvent], TestBatchService) -> Void) {
        self.maxQueueSizeTriggeringSending = maxQueueSizeTriggeringSending
        self.sendCalled = sendCalled
        super.init(sendBatchSize: 2)
        set(enabled: true)
    }

    override func shouldSendQueuedEvents() -> Bool {
        return self.queuedEvents.count >= self.maxQueueSizeTriggeringSending
    }

    override func send<Events: Collection>(events: Events) where Events.Element == SendingDelayedAnalyticsEvent {
        self.sendCalled(Array(events), self)
    }
}

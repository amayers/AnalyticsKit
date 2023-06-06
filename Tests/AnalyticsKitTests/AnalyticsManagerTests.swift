@testable import AnalyticsKit
import XCTest

final class AnalyticsManagerTests: XCTestCase {
    
    private let userDefaults = UserDefaults(suiteName: "AnalyticsManagerTests")!
    private let key = "AnalyticsManager_hasUserApprovedAnalytics"
    
    override func tearDown() {
        super.tearDown()
        userDefaults.removeObject(forKey: key)
    }

    func test_hasUserApprovedAnalytics() async throws {
        XCTAssertNil(userDefaults.object(forKey: key))
        
        let manager = AnalyticsManager(
            service: TestService(),
            userDefaults: userDefaults
        )
        XCTAssertTrue(manager.hasUserApprovedAnalytics)
        XCTAssertEqual(manager.hasUserApprovedAnalytics, userDefaults.bool(forKey: key))
        manager.hasUserApprovedAnalytics = false
        XCTAssertFalse(manager.hasUserApprovedAnalytics)
        XCTAssertEqual(manager.hasUserApprovedAnalytics, userDefaults.bool(forKey: key))
    }
    
    func test_logCustomEvent_addsToQueue_doesNotSend() async throws {
        let service = TestService { _, _, _ in
            XCTFail("The service shouldn't get the event yet")
        }
        let queue = EventQueue()
        let manager = AnalyticsManager(
            service: service,
            queue: queue,
            userDefaults: userDefaults
        )
        
        let event = MockEvent()
        let preLogEvents = await queue.events
        XCTAssertTrue(preLogEvents.isEmpty)
        await manager.logCustomEvent(event)
        let events = await queue.events
        XCTAssertEqual(events.count, 1)
    }
    
    func test_logCustomEvent_addsToQueue_sendsWhenEnoughEvents() async throws {
        let events = Array(repeating: MockEvent(), count: 10)
        
        let expectation = expectation(description: "Events sent")
        let service = TestService(batchSize: 20) { sentEvents, _, _ in
            XCTAssertEqual(events.count, sentEvents.count)
            expectation.fulfill()
        }
        let queue = EventQueue()
        let manager = AnalyticsManager(
            service: service,
            queue: queue,
            userDefaults: userDefaults
        )

        let preLogEvents = await queue.events
        XCTAssertTrue(preLogEvents.isEmpty)
        for event in events {
            await manager.logCustomEvent(event)
        }
        await fulfillment(of: [expectation])
        let postLogEvents = await queue.events
        XCTAssertTrue(postLogEvents.isEmpty)
    }
}

// MARK: -

private class TestService: Service {
    let sendCalled: (([SendingDelayedAnalyticsEvent], UUID, TestService) -> Void)?
    let batchSize: Int

    init(
        batchSize: Int = 2,
        sendCalled: (([SendingDelayedAnalyticsEvent], UUID, TestService) -> Void)? = nil
    ) {
        self.batchSize = batchSize
        self.sendCalled = sendCalled
    }
    func send<Events>(
        events: Events,
        for userID: UUID
    ) async throws where Events : Collection, Events.Element == SendingDelayedAnalyticsEvent {
        sendCalled?(Array(events), userID, self)
    }
}

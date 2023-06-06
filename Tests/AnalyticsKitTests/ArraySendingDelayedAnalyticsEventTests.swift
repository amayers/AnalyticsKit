@testable import AnalyticsKit
import XCTest

final class ArraySendingDelayedAnalyticsEventTests: XCTestCase {
    
    func test_oldestFirst() {
        let event0 = SendingDelayedAnalyticsEvent(event: MockEvent(), timeEventOccurred: Date())
        let event1 = SendingDelayedAnalyticsEvent(event: MockEvent(), timeEventOccurred: Date(timeIntervalSinceNow: -305))
        let unsorted = [event0, event1]
        let expected = [event1.timeEventOccurred, event0.timeEventOccurred]
        XCTAssertEqual(expected, unsorted.oldestFirst().map { $0.timeEventOccurred })
    }
    func test_shouldSendQueuedEvents_noConditionMet() {
        let array = Array(repeating: SendingDelayedAnalyticsEvent(event: MockEvent(), timeEventOccurred: Date(timeIntervalSinceNow: 600)), count: 1)
        XCTAssertFalse(array.shouldSendQueuedEvents())
    }
    
    func test_shouldSendQueuedEvents_countMet() {
        let array = Array(repeating: SendingDelayedAnalyticsEvent(event: MockEvent(), timeEventOccurred: Date()), count: 10)
        XCTAssertTrue(array.shouldSendQueuedEvents())
    }
    
    func test_shouldSendQueuedEvents_ageMet() {
        let array = [
            SendingDelayedAnalyticsEvent(event: MockEvent(), timeEventOccurred: Date()),
            SendingDelayedAnalyticsEvent(event: MockEvent(), timeEventOccurred: Date(timeIntervalSinceNow: -305))
        ]
        XCTAssertTrue(array.shouldSendQueuedEvents())
    }
}

@testable import CoreAnalytics
import XCTest

final class AtomicTests: XCTestCase {

    @Atomic
    private var mutateValue = 0
    func testMutate() {
        XCTAssertEqual(mutateValue, 0)
        mutateValue = 1
        XCTAssertEqual(mutateValue, 1)
        _mutateValue.mutate({ $0 += 1 })
        XCTAssertEqual(mutateValue, 2)
    }
}

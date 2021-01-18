import CoreAnalytics
import XCTest

class BytesTests: XCTestCase {

    func testKB() {
        let bytes = Bytes(2_048)
        let kilobytes = bytes.converted(to: .kilobytes)
        XCTAssertEqual(kilobytes, 2.0, accuracy: 0.01)
    }

    func testMB() {
        let bytes = Bytes(1_048_576)
        let megabytes = bytes.converted(to: .megabytes)
        XCTAssertEqual(megabytes, 1.0, accuracy: 0.01)
    }

    func testGB() {
        let bytes = Bytes(1_073_741_824)
        let megabytes = bytes.converted(to: .gigabytes)
        XCTAssertEqual(megabytes, 1.0, accuracy: 0.01)
    }
}

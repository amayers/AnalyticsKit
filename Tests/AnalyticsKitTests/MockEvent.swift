import AnalyticsKit

final class MockEvent: AnalyticsEvent, @unchecked Sendable {
    let name: String = "mock"
    
    let attributes: [String : AnalyticsEventAttribute]? = ["key1": 1, "key2": "two"]
    
    private(set) var hasBeenSent: Bool = false
    
    func wasSent() {
        hasBeenSent = true
    }
}

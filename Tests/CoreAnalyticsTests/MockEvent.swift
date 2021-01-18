import CoreAnalytics

class MockEvent: AnalyticsEvent {
    let name: String = "mock"
    
    let attributes: [String : Any]? = ["key1": 1, "key2": "two"]
    
    private(set) var hasBeenSent: Bool = false
    
    func wasSent() {
        hasBeenSent = true
    }
}

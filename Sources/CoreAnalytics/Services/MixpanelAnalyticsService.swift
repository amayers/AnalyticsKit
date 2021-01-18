import Foundation
import UIKit

/// Sends analytics to MixPanel
public final class MixPanelAnalyticsService: BatchSendingAnalyticsService {

    /// Create the analytics service
    /// - Parameter token: The MixPanel token for the app that you want all analytics events sent to.
    public init(token: String) {
        self.token = token

        super.init(sendBatchSize: 50)
    }

    override func send<Events: Collection>(events: Events) where Events.Element == SendingDelayedAnalyticsEvent {
        DispatchQueue.global(qos: .utility).async {
            let mixPanelEvents = events.map { MixPanelEvent(analyticsEvent: $0, token: self.token, distinctID: self.userID?.uuidString)}

            let jsonEncoder = JSONEncoder()
            jsonEncoder.dateEncodingStrategy = .secondsSince1970
            do {
                let jsonData = try jsonEncoder.encode(mixPanelEvents)
                let jsonString = jsonData.base64EncodedString()
                let bodyString = "data=\(jsonString)"

                var request = URLRequest(url: self.url())
                request.addValue(Constants.contentType, forHTTPHeaderField: "Content-Type")
                request.httpBody = bodyString.data(using: .utf8)
                request.httpMethod = Constants.httpMethod
                let task = self.session.dataTask(with: request, completionHandler: { (responseData, _, error) in
                    self.sending(events: events, finishedWith: responseData, error: error)
                })
                
                #if DEBUG
                if ProcessInfo.processInfo.environment["SEND_ANALYTICS_ON_DEBUG"] == "true" {
                    task.resume()
                } else {
                    print("Pretending to send \(events.count) to Mixpanel.")
                    print("Not actually sending because this is a DEBUG build.")
                    print("To override this set the environment variable SEND_ANALYTICS_ON_DEBUG=true")
                    // Clear out the events, as if they had been actually sent to MixPanel.
                    self.sending(events: events, finishedWith: nil, error: nil)
                }
                #else
                task.resume()
                #endif

            } catch {
                assertionFailure("Error encoding JSON: \(error)")
                self.sendingFailed(for: events)
            }
        }
    }

    // MARK: - Private

    private enum Constants {
        static let host = "api.mixpanel.com"
        static let eventEndpoint = "/track"
        static let scheme = "https"
        static let contentType = "application/x-www-form-urlencoded"
        static let httpMethod = "POST"
    }

    private let token: String
    private let session = URLSession.shared

    private func sending<Events: Collection>(events: Events,
                                             finishedWith data: Data?, error: Error?) where Events.Element == SendingDelayedAnalyticsEvent {
        if let error = error {
            assertionFailure("Error logging analytics: \(error)")
            sendingFailed(for: events)
        } else if let data = data, let responseString = String(data: data, encoding: .utf8), responseString != "1" {
            assertionFailure("Error logging analytics: \(responseString)")
            sendingFailed(for: events)
        }
    }

    private func url() -> URL {
        var components = URLComponents()
        components.host = Constants.host
        components.path = Constants.eventEndpoint
        components.scheme = Constants.scheme
        return components.url!
    }
}

private struct MixPanelEvent: Encodable {
    let analyticsEvent: SendingDelayedAnalyticsEvent

    /// Mixpanel's token that links the iOS consumer app with it's Mixpanel app record
    private let token: String
    /// An ID for this user so we can track their actions before/after this event as a flow
    private let distinctID: String?

    init(analyticsEvent: SendingDelayedAnalyticsEvent, token: String, distinctID: String?) {
        self.analyticsEvent = analyticsEvent
        self.token = token
        self.distinctID = distinctID
    }

    private enum CodingKeys: String, CodingKey {
        case event
        case properties
    }

    private struct AttributesCodingKey: CodingKey {
        let stringValue: String
        init?(stringValue: String) {
            self.stringValue = stringValue
        }
        let intValue: Int? = nil
        init?(intValue: Int) {
            return nil
        }
    }

    func encode(to encoder: Encoder) throws {
        var rootContainer = encoder.container(keyedBy: CodingKeys.self)
        try rootContainer.encode(self.analyticsEvent.event.name, forKey: .event)

        var propertiesContainer = rootContainer.nestedContainer(keyedBy: AttributesCodingKey.self, forKey: .properties)
        try propertiesContainer.encode(self.token, forKey: AttributesCodingKey(stringValue: "token")!)
        try propertiesContainer.encode(self.analyticsEvent.timeEventOccurred, forKey: AttributesCodingKey(stringValue: "time")!)
        try propertiesContainer.encodeIfPresent(self.distinctID, forKey: AttributesCodingKey(stringValue: "distinct_id")!)
        if let customProperties = self.analyticsEvent.event.attributes {
            try customProperties.forEach { (key, value) in
                let codingKey = AttributesCodingKey(stringValue: key)!
                if let intValue = value as? Int {
                    try propertiesContainer.encode(intValue, forKey: codingKey)
                } else if let doubleValue = value as? Double {
                    try propertiesContainer.encode(doubleValue, forKey: codingKey)
                } else if let stringValue = value as? String {
                    try propertiesContainer.encode(stringValue, forKey: codingKey)
                } else if let boolValue = value as? Bool {
                    try propertiesContainer.encode(boolValue, forKey: codingKey)
                } else {
                    assertionFailure("Encountered a custom analytics parameter that isn't an Int, Double, Bool or String")
                }
            }
        }
    }
}

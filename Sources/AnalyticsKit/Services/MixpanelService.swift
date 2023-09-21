import Foundation
import OSLog

public final class MixpanelService: Service {
    
    enum Error: Swift.Error {
        case mixpanelResponseFailure
    }
    
    private enum Constants {
        static let host = "api.mixpanel.com"
        static let eventEndpoint = "/track"
        static let scheme = "https"
        static let contentType = "application/x-www-form-urlencoded"
        static let httpMethod = "POST"
        static let batchSize = 50
    }
    
    // MARK: - Private Properties
    
    private let logger: Logger
    private let session: URLSession
    private let token: String
    
    // MARK: - Public Properties
    
    public let batchSize: Int = Constants.batchSize
    
    
    // MARK: - Life Cycle

    /// Create the analytics service
    /// - Parameter token: The MixPanel token for the app that you want all analytics events sent to.
    public init(token: String, session: URLSession = .shared) {
        self.logger = Logger.analyticsLogger(category: String(describing: Self.self))
        self.token = token
        self.session = session
    }
    
    // MARK: - Public Methods
    
    public func send<Events>(
        events: Events,
        for userID: UUID
    ) async throws where Events : Collection, Events.Element == SendingDelayedAnalyticsEvent {
        let mixPanelEvents = events.map {
            MixPanelEvent(analyticsEvent: $0, token: token, distinctID: userID.uuidString)
        }

        let jsonEncoder = JSONEncoder()
        jsonEncoder.dateEncodingStrategy = .secondsSince1970
        
        let jsonData = try jsonEncoder.encode(mixPanelEvents)
        let jsonString = jsonData.base64EncodedString()
        let bodyString = "data=\(jsonString)"

        var request = URLRequest(url: self.url())
        request.addValue(Constants.contentType, forHTTPHeaderField: "Content-Type")
        request.httpBody = bodyString.data(using: .utf8)
        request.httpMethod = Constants.httpMethod
        
#if DEBUG
        if ProcessInfo.processInfo.environment["SEND_ANALYTICS_ON_DEBUG"] != "true" {
            logger.debug(
                """
                Pretending to send \(events.count) to Mixpanel.
                Not actually sending because this is a DEBUG build.
                To override this set the environment variable SEND_ANALYTICS_ON_DEBUG=true
                """
            )
            return
        }
#endif
        
        let (data, _) = try await session.data(for: request)
        if let responseString = String(data: data, encoding: .utf8), responseString == "1" {
            logger.info("Sent \(events.count) events successfully to Mixpanel.")
        } else {
            throw Error.mixpanelResponseFailure
        }
    }
    
    // MARK: - Private Methods
    
    private func url() -> URL {
        var components = URLComponents()
        components.host = Constants.host
        components.path = Constants.eventEndpoint
        components.scheme = Constants.scheme
        return components.url!
    }
}

// MARK: -

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
        
        let encodeProperties: ([String: Any]) throws -> Void = { properties in
            try properties.forEach { (key, value) in
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
                    assertionFailure("Encountered a custom analytics parameter \(key) that isn't an Int, Double, Bool or String")
                }
            }
        }
        
        if let customProperties = self.analyticsEvent.event.attributes {
            try encodeProperties(customProperties)
        }
        if analyticsEvent.event.shouldSendStandardAttributes {
            try encodeProperties(analyticsEvent.event.standardAttributes)
        }
    }
}

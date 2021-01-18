import Foundation

/// Gets some basic info (version, build, userIdentifier) about the current app install.
public struct AppInfo {
    public let version: String
    public let build: String
    public let userIdentifier: String

    public init() {
        self.userIdentifier = UserIdentifier.identifierForVendor().uuidString
        if let dictionary = Bundle.main.infoDictionary,
            let version = dictionary["CFBundleShortVersionString"] as? String,
            let build = dictionary["CFBundleVersion"] as? String {
            self.version = version
            self.build = build
        } else {
            self.version = "unknown"
            self.build = self.version
        }
    }
}

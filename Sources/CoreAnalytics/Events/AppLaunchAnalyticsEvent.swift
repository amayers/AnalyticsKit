import UIKit

/// This event should be sent every time the app is launched. It identifies the OS version, app version, device model info, and locale details
public struct AppLaunchAnalyticsEvent: AnalyticsEvent {
    public let name = "app_launch"

    public var attributes: [String: Any]? {
        [
            "ios_version": self.device.osVersion,
            "app_version": self.app.version,
            "app_build": self.app.build,
            "device_model": self.device.device.modelCode,
            "device_description": self.device.device.model.rawValue,
            "ram_size_mb": self.device.ramSizeMB,
            "free_disk_space_mb": self.device.freeDiskSpaceMB,
            "language_code": Locale.current.languageCode ?? "unknown",
            "region_code": Locale.current.regionCode ?? "unknown",
            "locale_identifier": Locale.current.identifier
        ]
    }

    public init() {
        self.app = AppInfo()
        self.device = DeviceInfo()

        print("""
            App launched
            version: \(app.version) (\(app.build)),
            iOS: \(device.osVersion),
            device model code: \(device.device.modelCode),
            device description: \(device.device.model.rawValue),
            user id: \(app.userIdentifier),
            RAM: \(device.ramSizeMB) MB,
            free disk space: \(device.freeDiskSpaceMB) MB
            """)
    }

    public func wasSent() { }

    // MARK: - Private

    private let app: AppInfo
    private let device: DeviceInfo
}

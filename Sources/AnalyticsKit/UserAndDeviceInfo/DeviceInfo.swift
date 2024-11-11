import UIKit

/// Gets some basic info about the current device/OS
public struct DeviceInfo {
    public let osVersion: String
    public let deviceModelIdentifier = Platform.modelIdentifier

    @MainActor
    public init() {
        self.osVersion = UIDevice.current.systemVersion
    }
}

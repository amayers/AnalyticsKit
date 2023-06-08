import UIKit

/// Gets some basic info about the current device/OS
public struct DeviceInfo {
    public let osVersion: String
    public let ramSizeMB: Int
    public let freeDiskSpaceMB: Int
    public let deviceModelIdentifier = Platform.modelIdentifier

    public init() {
        self.osVersion = UIDevice.current.systemVersion
        self.ramSizeMB = Int(Platform.deviceRAM.converted(to: .megabytes))
        self.freeDiskSpaceMB = Int((UIDevice.current.freeDiskSpace() ?? 0).converted(to: .megabytes))
    }
}

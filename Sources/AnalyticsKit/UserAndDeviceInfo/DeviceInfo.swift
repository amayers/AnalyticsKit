import UIKit

/// Gets some basic info about the current device/OS
public struct DeviceInfo {
    public let osVersion: String
    public let ramSizeMB: Int
    public let freeDiskSpaceMB: Int
    public let device: Platform.Device

    public init() {
        self.osVersion = UIDevice.current.systemVersion
        self.ramSizeMB = Int(Platform.deviceRAM.converted(to: .megabytes))
        self.device = Platform.device
        self.freeDiskSpaceMB = Int((UIDevice.current.freeDiskSpace() ?? 0).converted(to: .megabytes))
    }
}

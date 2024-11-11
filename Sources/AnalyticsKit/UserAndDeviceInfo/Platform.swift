import Foundation
import Metal

/// Information about the current platform that the app is running on.
/// Is it a simulator, or device. Which device?
public enum Platform {
    public static var isSimulator: Bool { return TARGET_OS_SIMULATOR != 0 }

    /// Returns true if the code is running as part of a unit/integration test
    public static var isRunningTests: Bool {
        if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil ||
            ProcessInfo.processInfo.environment["DYLD_INSERT_LIBRARIES"]?.contains("libXCTTargetBootstrapInject.dylib") == .some(true) {
            return true
        } else {
            return false
        }
    }

    /// Identifier such as `iPhone4,1` to identify a specific model.
    public static let modelIdentifier: String = {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let modelIdentifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return modelIdentifier
    }()
}

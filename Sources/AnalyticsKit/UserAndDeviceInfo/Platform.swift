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
    public static var modelIdentifier: String = {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let modelIdentifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return modelIdentifier
    }()

    /// How much total RAM does this device have.
    public static var deviceRAM: Bytes = {
        return ProcessInfo.processInfo.physicalMemory
    }()

    public struct Memory {
        public let used: Bytes
        public let free: Bytes
    }

    public static var deviceMemoryDetails: Memory {
        var pageSize: vm_size_t = 0

        let hostPort: mach_port_t = mach_host_self()
        var hostSize: mach_msg_type_number_t = mach_msg_type_number_t(MemoryLayout<vm_statistics_data_t>.stride / MemoryLayout<integer_t>.stride)
        host_page_size(hostPort, &pageSize)

        var vmStat: vm_statistics = vm_statistics_data_t()
        withUnsafeMutablePointer(to: &vmStat) { (vmStatPointer) -> Void in
            vmStatPointer.withMemoryRebound(to: integer_t.self, capacity: Int(hostSize)) {
                if host_statistics(hostPort, HOST_VM_INFO, $0, &hostSize) != KERN_SUCCESS {
                    NSLog("Error: Failed to fetch vm statistics")
                }
            }
        }

        let used = Bytes(vmStat.active_count + vmStat.inactive_count + vmStat.wire_count) * Bytes(pageSize)
        let free = Bytes(vmStat.free_count) * Bytes(pageSize)
        return Memory(used: used, free: free)
    }
}

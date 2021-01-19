import Foundation
import Metal

/// Information about the current platform that the app is running on.
/// Is it a simulator, or device. Which device?
public enum Platform {
    public static var isSimulator: Bool { return TARGET_OS_SIMULATOR != 0 }

    /// Does the current iOS device's GPU support Metal.
    public static var isMetalSupported: Bool {
        /// If an iOS device has absolutely no Metal support then the `MTLCreateSystemDefaultDevice()` will return nil.
        if let device = MTLCreateSystemDefaultDevice() {
            // The first GPU family is A7 devices, that have such limited Metal support that basically nothing Metal works on them.
            // So we will pretend that they don't support Metal at all. Infact most of Apple's docs say that the Metal support is only on >= A8
            #if targetEnvironment(macCatalyst)
            return true
            #else
            return device.supportsFeatureSet(.iOS_GPUFamily2_v1)
            #endif
        }

        return false
    }

    /// Returns true if the code is running as part of a unit/integration test
    public static var isRunningTests: Bool {
        if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil ||
            ProcessInfo.processInfo.environment["DYLD_INSERT_LIBRARIES"]?.contains("libXCTTargetBootstrapInject.dylib") == .some(true) {
            return true
        } else {
            return false
        }
    }

    public struct Device {
        public let model: Model
        public let modelCode: String
    }

    public enum Model: String {
        case simulator   = "simulator/sandbox",
        iPod1            = "iPod 1",
        iPod2            = "iPod 2",
        iPod3            = "iPod 3",
        iPod4            = "iPod 4",
        iPod5            = "iPod 5",
        iPod6            = "iPod 6",
        iPod7            = "iPod 7",
        iPad2            = "iPad 2",
        iPad3            = "iPad 3",
        iPad4            = "iPad 4",
        iPad6            = "iPad 6",
        iPad7            = "iPad 7",
        iPhone4          = "iPhone 4",
        iPhone4S         = "iPhone 4S",
        iPhone5          = "iPhone 5",
        iPhone5S         = "iPhone 5S",
        iPhone5C         = "iPhone 5C",
        iPadMini1        = "iPad Mini 1",
        iPadMini2        = "iPad Mini 2",
        iPadMini3        = "iPad Mini 3",
        iPadMini4        = "iPad Mini 4",
        iPadMini5        = "iPad Mini 5",
        iPadAir1         = "iPad Air 1",
        iPadAir2         = "iPad Air 2",
        iPadAir2Cell     = "iPad Air 2 cellular",
        iPadAir3         = "iPad Air 3",
        iPadPro97       = "iPad Pro 9.7\"",
        iPadPro97Cell  = "iPad Pro 9.7\" cellular",
        iPadPro105      = "iPad Pro 10.5\"",
        iPadPro105Cell = "iPad Pro 10.5\" cellular",
        iPadPro11       = "iPad Pro 11\"",
        iPadPro11Cell   = "iPad Pro 11\" cellular",
        iPadPro11Gen2   = "iPad Pro 11\" (2nd gen)",
        iPadPro11CellGen2 = "iPad Pro 11\" cellular (2nd gen)",
        iPadPro129      = "iPad Pro 12.9\"",
        iPadPro129Cell = "iPad Pro 12.9\" cellular",
        iPadPro129Gen2     = "iPad Pro 12.9\" (2nd gen)",
        iPadPro129CellGen2 = "iPad Pro 12.9\" cellular (2nd gen)",
        iPadPro129Gen3     = "iPad Pro 12.9\" (3rd gen)",
        iPadPro129CellGen3 = "iPad Pro 12.9\" cellular (3rd gen)",
        iPadPro129Gen4     = "iPad Pro 12.9\" (4th gen)",
        iPadPro129CellGen4 = "iPad Pro 12.9\" cellular (4th gen)",
        // It appears that M1 equipped Macs report as the iPad pro 12.9" 1TB 3rd gen
        // It also could be one of those iPads. However the 3rd gen 1TB 12.9" is a pretty rare model, that is also
        // no longer sold. So if we see many of these, it's likely a Mac.
        iPadPro129Gen3_1TbOrMacM1 = "iPad Pro 12.9-inch 1TB (3rd gen) OR Mac with M1",
        iPhone6          = "iPhone 6",
        iPhone6Plus      = "iPhone 6 Plus",
        iPhone6S         = "iPhone 6S",
        iPhone6SPlus     = "iPhone 6S Plus",
        iPhoneSE         = "iPhone SE",
        iPhoneSEGen2     = "iPhone SE (2nd gen)",
        iPhone7          = "iPhone 7",
        iPhone7Plus      = "iPhone 7 Plus",
        iPhone8          = "iPhone 8",
        iPhone8Plus      = "iPhone 8 Plus",
        iPhoneX          = "iPhone X",
        iPhoneXs         = "iPhone Xs",
        iPhoneXsMax      = "iPhone Xs Max",
        iPhoneXr         = "iPhone Xr",
        iPhone11         = "iPhone 11",
        iPhone11Pro      = "iPhone 11 Pro",
        iPhone11ProMax   = "iPhone 11 Pro Max",
        iPhone12Mini     = "iPhone 12 mini",
        iPhone12         = "iPhone 12",
        iPhone12Pro      = "iPhone 12 Pro",
        iPhone12ProMax   = "iPhone 12 Pro Max",
        unrecognized     = "Unrecognized"
    }

    public static var device: Device {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let modelCode = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }

        /// Apple uses identifiers like iPhone4,1 for their devices. There are often varients of their devices that
        /// are either slightly different for different markets, or cell vs wifi models. The first number is the
        /// primary model, and the second is any small variations (wifi vs cell vs international).
        /// Typically we don't want to see these raw model numbers in our analytics. We also don't want our analytics
        /// split up by sub-model number. We primarily care about iPhone 7 vs iPhone 11 usage, so this maps those
        /// detailed model numbers, to a more generic identifier. We should log both the raw `modelCode` and `Model`.
        /// That way most of the time we can use `Model` since its higher level, but if a new model comes out,
        /// we will at least capture it's `modelCode` until we add it to our `Model`.
        let modelMap: [String: Model] = [
            "i386": .simulator,
            "x86_64": .simulator,
            "iPod1,1": .iPod1,
            "iPod2,1": .iPod2,
            "iPod3,1": .iPod3,
            "iPod4,1": .iPod4,
            "iPod5,1": .iPod5,
            "iPod7,1": .iPod6,
            "iPod9,1": .iPod7,
            "iPad2,1": .iPad2,
            "iPad2,2": .iPad2,
            "iPad2,3": .iPad2,
            "iPad2,4": .iPad2,
            "iPad2,5": .iPadMini1,
            "iPad2,6": .iPadMini1,
            "iPad2,7": .iPadMini1,
            "iPhone3,1": .iPhone4,
            "iPhone3,2": .iPhone4,
            "iPhone3,3": .iPhone4,
            "iPhone4,1": .iPhone4S,
            "iPhone5,1": .iPhone5,
            "iPhone5,2": .iPhone5,
            "iPhone5,3": .iPhone5C,
            "iPhone5,4": .iPhone5C,
            "iPad3,1": .iPad3,
            "iPad3,2": .iPad3,
            "iPad3,3": .iPad3,
            "iPad3,4": .iPad4,
            "iPad3,5": .iPad4,
            "iPad3,6": .iPad4,
            "iPhone6,1": .iPhone5S,
            "iPhone6,2": .iPhone5S,
            "iPad4,1": .iPadAir1,
            "iPad4,2": .iPadAir1,
            "iPad4,4": .iPadMini2,
            "iPad4,5": .iPadMini2,
            "iPad4,6": .iPadMini2,
            "iPad4,7": .iPadMini3,
            "iPad4,8": .iPadMini3,
            "iPad4,9": .iPadMini3,
            "iPad5,3": .iPadAir2,
            "iPad5,4": .iPadAir2Cell,
            "iPad5,1": .iPadMini4,
            "iPad5,2": .iPadMini4,
            "iPad6,3": .iPadPro97,
            "iPad6,11": .iPadPro97,
            "iPad6,4": .iPadPro97Cell,
            "iPad6,12": .iPadPro97Cell,
            "iPad6,7": .iPadPro129,
            "iPad6,8": .iPadPro129Cell,
            "iPad7,1": .iPadPro129Gen2,
            "iPad7,2": .iPadPro129CellGen2,
            "iPad7,3": .iPadPro105,
            "iPad7,4": .iPadPro105Cell,
            "iPad7,5": .iPad6,
            "iPad7,6": .iPad6,
            "iPad7,11": .iPad7,
            "iPad7,12": .iPad7,
            "iPad8,1": .iPadPro11,
            "iPad8,2": .iPadPro11,
            "iPad8,3": .iPadPro11Cell,
            "iPad8,4": .iPadPro11Cell,
            "iPad8,5": .iPadPro129Gen3,
            "iPad8,6": .iPadPro129Gen3_1TbOrMacM1,
            "iPad8,7": .iPadPro129CellGen3,
            "iPad8,8": .iPadPro129CellGen3,
            "iPad8,9": .iPadPro11Gen2,
            "iPad8,10": .iPadPro11CellGen2,
            "iPad8,11": .iPadPro129Gen4,
            "iPad8,12": .iPadPro129CellGen4,
            "iPad11,1": .iPadMini5,
            "iPad11,2": .iPadMini5,
            "iPad11,3": .iPadAir3,
            "iPad11,4": .iPadAir3,
            "iPhone7,1": .iPhone6Plus,
            "iPhone7,2": .iPhone6,
            "iPhone8,1": .iPhone6S,
            "iPhone8,2": .iPhone6SPlus,
            "iPhone8,4": .iPhoneSE,
            "iPhone9,1": .iPhone7,
            "iPhone9,2": .iPhone7Plus,
            "iPhone9,3": .iPhone7,
            "iPhone9,4": .iPhone7Plus,
            "iPhone10,1": .iPhone8,
            "iPhone10,2": .iPhone8Plus,
            "iPhone10,3": .iPhoneX,
            "iPhone10,4": .iPhone8,
            "iPhone10,5": .iPhone8Plus,
            "iPhone10,6": .iPhoneX,
            "iPhone11,2": .iPhoneXs,
            "iPhone11,4": .iPhoneXsMax,
            "iPhone11,6": .iPhoneXsMax,
            "iPhone11,8": .iPhoneXr,
            "iPhone12,1": .iPhone11,
            "iPhone12,3": .iPhone11Pro,
            "iPhone12,5": .iPhone11ProMax,
            "iPhone12,8": .iPhoneSEGen2,
            "iPhone13,1": .iPhone12Mini,
            "iPhone13,2": .iPhone12,
            "iPhone13,3": .iPhone12Pro,
            "iPhone13,4": .iPhone12ProMax
        ]

        if let model = modelMap[modelCode] {
            return Device(model: model, modelCode: modelCode)
        }
        return Device(model: .unrecognized, modelCode: modelCode)
    }

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

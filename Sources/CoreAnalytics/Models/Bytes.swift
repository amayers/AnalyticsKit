import Foundation

public typealias Bytes = UInt64

public extension Bytes {
    enum Units {
        case kilobytes
        case megabytes
        case gigabytes
    }

    /// Converts bytes into different units
    /// - Parameter units: The desired units that you want the returned value in.
    func converted(to units: Units) -> Double {
        switch units {
        case .kilobytes:
            return Double(self) / 1024
        case .megabytes:
            return Double(self) / 1024 / 1024
        case .gigabytes:
            return Double(self) / 1024 / 1024 / 1024
        }
    }
}

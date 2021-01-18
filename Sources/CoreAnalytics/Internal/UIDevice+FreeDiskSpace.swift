import UIKit

extension UIDevice {
    /// The amount of free disk space on this iOS device. This includes current free space, and the total purgeable space that the system will free up as you
    /// fill to near capacity.
    func freeDiskSpace() -> Bytes? {
        do {
            let url = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            let resourceValues = try url.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])
            if let freeSpace = resourceValues.volumeAvailableCapacityForImportantUsage {
                return Bytes(freeSpace)
            }
        } catch {
            print("Error trying to get the amount of free disk space: \(error)")
        }
        return nil
    }
}

import UIKit

public enum UserIdentifier {
    private enum Constants {
        static let identifierForVendorKey = "IdentifierForVendor"
    }

    /// An alternative to `UIDevice.current.identifierForVendor`, since that can return nil, if it does then we make up a UUID
    /// and save it so we get the same value for every launch of the app (until the app is deleted).
    public static func identifierForVendor() -> UUID {
        if let savedUUIDString = UserDefaults.standard.string(forKey: Constants.identifierForVendorKey), let uuid = UUID(uuidString: savedUUIDString) {
            return uuid
        } else {
            let uuid = UIDevice.current.identifierForVendor ?? UUID()
            UserDefaults.standard.setValue(uuid.uuidString, forKey: Constants.identifierForVendorKey)
            return uuid
        }
    }
}

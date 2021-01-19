import Foundation

/// An analytics event that keeps track if it has been logged before or not. Either way this even will be logged, but conformers to this
/// can choose to change their event name, or properties based on being logged before or not. A common use case will be for logging
/// both a unique version and repeated version of the same event.
protocol UniqueAnalyticsEvent: AnalyticsEvent {
    /// A key that uniquely identifies this event's properties. It might want to combine the experienceID, renderID, and photo index
    /// to make a unique key for an event tracking photo views
    var specificKey: String { get }
}

extension UniqueAnalyticsEvent {

    /// Has this specific event been logged before. Specific means a combination of the same type conforming to this protocol AND the `specificKey` value
    var hasEventBeenLoggedBefore: Bool {
        return Self.overallDictionary()[specificKey] ?? false
    }

    /// Change the value of `hasEventBeenLoggedBefore` to be new value. This must be a function instead of a setter on `hasEventBeenLoggedBefore` because that
    /// would mean conformers to this protocol must be mutable, which complicates things.
    func setEventHasBeen(logged: Bool) {
        var dict = Self.overallDictionary()
        dict[specificKey] = logged
        UserDefaults.standard.set(dict, forKey: Self.overallKey)
    }

    /// Resets all the uniqueness checkers for the type conforming to this `UniqueAnalyticsEvent`.
    static func resetAll() {
        UserDefaults.standard.removeObject(forKey: overallKey)
    }

    private static var overallKey: String {
        return String(describing: self)
    }

    private static func overallDictionary() -> [String: Bool] {
        if let dict = UserDefaults.standard.dictionary(forKey: overallKey) as? [String: Bool] {
            return dict
        } else {
            return [:]
        }
    }
}

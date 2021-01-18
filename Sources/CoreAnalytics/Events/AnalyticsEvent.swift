import Foundation

public protocol AnalyticsEvent {
    var name: String { get }
    var attributes: [String: Any]? { get }
    /// This method will be called by the analytics manager when the event was sent. Use this to do any work needed to finalize the event.
    /// Using this prevents having to do things like recording a unique event on the event's init. That way the `init` doesn't modify state.
    /// It may be called on any queue.
    func wasSent()
}

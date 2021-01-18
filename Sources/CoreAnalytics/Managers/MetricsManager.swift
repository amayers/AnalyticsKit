import MetricKit
import UIKit

/// With iOS 13 Apple added `MetricKit` which sends device metrics (CPU, GPU, Disk usage, battery usage) both back to Apple
/// where we can view it in Xcode's organizer, as well as delivering them in the `didReceive` method below so if we wanted any custom logging of them.
/// On 13 we get the ability to view production data in Xcode from customer's devices.
public final class MetricsManager: NSObject {

    override init() {
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillTerminate(_:)),
                                               name: UIApplication.willTerminateNotification, object: nil)
        MXMetricManager.shared.add(self)
    }

    /// Thin wrapper around `makeLogHandle(category:)` in `MetricKit`.
    /// Returns a log handle used for writing custom metric events.
    /// - Parameter category: A developer-specified string containing the name of the category of custom metrics written to the log.
    public static func makeLogHandle(category: String) -> OSLog {
        return MXMetricManager.makeLogHandle(category: category)
    }

    /// Thin wrapper around `mxSignPost(type:log:name:)` in `MetricKit`.
    /// Post a single custom metric, the start time of a custom metric, or the end time of a custom metric to metric kit log.
    /// - Parameters:
    ///   - type: A value of determining the role of the signpost which determines the type of post.
    ///   - log: A log for the category of the event that was created previously using `makeLogHandle(category:)`
    ///   - name: A string containing developer assigned name of the custom event.
    public static func signpost(type: OSSignpostType, log: OSLog, name: StaticString) {
        mxSignpost(type, log: log, name: name)
    }
}

// MARK: - MXMetricManagerSubscriber

extension MetricsManager: MXMetricManagerSubscriber {

    @objc
    private func applicationWillTerminate(_ application: UIApplication) {
        MXMetricManager.shared.remove(self)
    }

    public func didReceive(_ payloads: [MXMetricPayload]) {
        // For now we don't need to do anything custom with the metrics, just by registering for them we should now be getting them in Xcode.
    }
}

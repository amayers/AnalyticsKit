import OSLog

extension Logger {
    static func analyticsLogger(category: String) -> Logger {
        Logger(subsystem: Bundle.main.bundleIdentifier ?? "AnalyticsKit", category: category)
    }
}

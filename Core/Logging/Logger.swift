import Foundation
import os

/// Structured logger for BodyMetric (Constitution Principle III).
///
/// All errors caught at any `catch` site MUST be logged here before being handled,
/// swallowed, or surfaced to the user. Silent failures are a defect.
///
/// Rules enforced:
///  - Every entry includes timestamp, severity, source location, and message.
///  - No PII (email, display name, raw tokens) may appear in any log output.
///
/// Backend: Apple Unified Logging (OSLog). Entries are visible in:
///  - Xcode Console (⌘⇧C) while running on simulator/device.
///  - Terminal: `log stream --predicate 'subsystem == "com.bodymetric.app"' --level debug`
///  - Console.app filtered by process "BodyMetric".
enum Logger {

    // MARK: - OSLog subsystem

    private static let subsystem = "com.bodymetric.app"

    private static let general  = os.Logger(subsystem: subsystem, category: "general")
    private static let auth     = os.Logger(subsystem: subsystem, category: "auth")
    private static let network  = os.Logger(subsystem: subsystem, category: "network")
    private static let security = os.Logger(subsystem: subsystem, category: "security")

    // MARK: - Public API

    /// Verbose developer information. Stripped in release builds by OSLog.
    static func debug(
        _ message: String,
        category: Category = .general,
        file: String = #fileID,
        function: String = #function,
        line: Int = #line
    ) {
        let logger = osLogger(for: category)
        logger.debug("[\(shortFile(file))] \(function):\(line) — \(message)")
        print("🔍 DEBUG [\(shortFile(file)):\(line)] \(message)")
    }

    /// Informational milestone. Useful for flow tracing.
    static func info(
        _ message: String,
        category: Category = .general,
        file: String = #fileID,
        function: String = #function,
        line: Int = #line
    ) {
        let logger = osLogger(for: category)
        logger.info("[\(shortFile(file))] \(function):\(line) — \(message)")
        print("ℹ️  INFO  [\(shortFile(file)):\(line)] \(message)")
    }

    /// Something unexpected happened but the app can continue.
    static func warning(
        _ message: String,
        category: Category = .general,
        file: String = #fileID,
        function: String = #function,
        line: Int = #line
    ) {
        let logger = osLogger(for: category)
        logger.warning("[\(shortFile(file))] \(function):\(line) — \(message)")
        print("⚠️  WARN  [\(shortFile(file)):\(line)] \(message)")
    }

    /// An error occurred. Must be called at every `catch` site before handling.
    /// - Parameter error: The caught error. Its `localizedDescription` is logged.
    ///   Do NOT pass raw user data or tokens here.
    static func error(
        _ message: String,
        error: Error? = nil,
        category: Category = .general,
        file: String = #fileID,
        function: String = #function,
        line: Int = #line
    ) {
        let detail = error.map { " | error: \($0.localizedDescription)" } ?? ""
        let logger = osLogger(for: category)
        logger.error("[\(shortFile(file))] \(function):\(line) — \(message)\(detail)")
        print("❌ ERROR [\(shortFile(file)):\(line)] \(message)\(detail)")
    }

    /// A critical failure that likely makes continued execution impossible.
    static func fault(
        _ message: String,
        category: Category = .general,
        file: String = #fileID,
        function: String = #function,
        line: Int = #line
    ) {
        let logger = osLogger(for: category)
        logger.fault("[\(shortFile(file))] \(function):\(line) — \(message)")
        print("🔥 FAULT [\(shortFile(file)):\(line)] \(message)")
    }

    // MARK: - Log categories

    enum Category {
        case general, auth, network, security
    }

    // MARK: - Private helpers

    private static func osLogger(for category: Category) -> os.Logger {
        switch category {
        case .general:  return general
        case .auth:     return auth
        case .network:  return network
        case .security: return security
        }
    }

    /// Strips the module prefix from `#fileID` for compact output.
    private static func shortFile(_ fileID: String) -> String {
        fileID.components(separatedBy: "/").last ?? fileID
    }
}

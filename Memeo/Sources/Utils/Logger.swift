import Foundation
import os

/// Singleton logger for the Memeo app
/// Currently uses standard iOS logging but can be extended to send logs elsewhere
public final class Logger {
    
    // MARK: - Singleton
    public static let shared = Logger()
    
    // MARK: - Properties
    private let subsystem = Bundle.main.bundleIdentifier ?? "com.memeo.app"
    private var loggers: [LogCategory: os.Logger] = [:]
    
    // MARK: - Log Categories
    public enum LogCategory: String, CaseIterable {
        case app = "App"
        case viewModel = "ViewModel"
        case userInteraction = "UserInteraction"
        case videoProcessing = "VideoProcessing"
        case fileOperations = "FileOperations"
        case networking = "Networking"
        case tracking = "Tracking"
        case export = "Export"
        case error = "Error"
        case performance = "Performance"
    }
    
    // MARK: - Log Levels
    public enum LogLevel {
        case debug
        case info
        case notice
        case warning
        case error
        case fault
        
        var osLogType: OSLogType {
            switch self {
            case .debug: return .debug
            case .info: return .info
            case .notice: return .default
            case .warning: return .error
            case .error: return .error
            case .fault: return .fault
            }
        }
    }
    
    // MARK: - Initialization
    private init() {
        // Initialize loggers for each category
        for category in LogCategory.allCases {
            loggers[category] = os.Logger(subsystem: subsystem, category: category.rawValue)
        }
    }
    
    // MARK: - Public Methods
    
    /// Log a message with specified category and level
    public func log(_ message: String, category: LogCategory = .app, level: LogLevel = .info, file: String = #file, function: String = #function, line: Int = #line) {
        let logger = loggers[category] ?? os.Logger()
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        let logMessage = "[\(fileName):\(line)] \(function) - \(message)"
        
        logger.log(level: level.osLogType, "\(logMessage)")
    }
    
    /// Log debug message
    public func debug(_ message: String, category: LogCategory = .app, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, category: category, level: .debug, file: file, function: function, line: line)
    }
    
    /// Log info message
    public func info(_ message: String, category: LogCategory = .app, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, category: category, level: .info, file: file, function: function, line: line)
    }
    
    /// Log notice message
    public func notice(_ message: String, category: LogCategory = .app, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, category: category, level: .notice, file: file, function: function, line: line)
    }
    
    /// Log warning message
    public func warning(_ message: String, category: LogCategory = .app, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, category: category, level: .warning, file: file, function: function, line: line)
    }
    
    /// Log error message
    public func error(_ message: String, category: LogCategory = .app, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, category: category, level: .error, file: file, function: function, line: line)
    }
    
    /// Log fault message
    public func fault(_ message: String, category: LogCategory = .app, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, category: category, level: .fault, file: file, function: function, line: line)
    }
    
    // MARK: - Event Logging
    
    /// Log a user interaction event
    public func logUserInteraction(_ action: String, details: [String: Any]? = nil, file: String = #file, function: String = #function, line: Int = #line) {
        var message = "User Action: \(action)"
        if let details = details {
            let detailsString = details.map { "\($0.key): \($0.value)" }.joined(separator: ", ")
            message += " | Details: [\(detailsString)]"
        }
        log(message, category: .userInteraction, level: .info, file: file, function: function, line: line)
    }
    
    /// Log a performance metric
    public func logPerformance(_ operation: String, duration: TimeInterval, details: [String: Any]? = nil, file: String = #file, function: String = #function, line: Int = #line) {
        var message = "Performance: \(operation) took \(String(format: "%.3f", duration))s"
        if let details = details {
            let detailsString = details.map { "\($0.key): \($0.value)" }.joined(separator: ", ")
            message += " | Details: [\(detailsString)]"
        }
        log(message, category: .performance, level: .info, file: file, function: function, line: line)
    }
    
    /// Log an error with optional underlying error
    public func logError(_ message: String, error: Error? = nil, category: LogCategory = .error, file: String = #file, function: String = #function, line: Int = #line) {
        var fullMessage = message
        if let error = error {
            fullMessage += " | Error: \(error.localizedDescription)"
        }
        log(fullMessage, category: category, level: .error, file: file, function: function, line: line)
    }
    
    // MARK: - Lifecycle Events
    
    /// Log app lifecycle events
    public func logAppLifecycle(_ event: String, details: [String: Any]? = nil) {
        logUserInteraction("App Lifecycle: \(event)", details: details)
    }
    
    /// Log view lifecycle events
    public func logViewLifecycle(_ viewName: String, event: String, details: [String: Any]? = nil) {
        logUserInteraction("View Lifecycle: \(viewName) - \(event)", details: details)
    }
}

// MARK: - Convenience Extensions

extension Logger {
    /// Measure and log the execution time of a block
    public func measureTime<T>(_ operation: String, category: LogCategory = .performance, block: () throws -> T) rethrows -> T {
        let startTime = CFAbsoluteTimeGetCurrent()
        defer {
            let duration = CFAbsoluteTimeGetCurrent() - startTime
            logPerformance(operation, duration: duration)
        }
        return try block()
    }
    
    /// Measure and log the execution time of an async block
    public func measureTimeAsync<T>(_ operation: String, category: LogCategory = .performance, block: () async throws -> T) async rethrows -> T {
        let startTime = CFAbsoluteTimeGetCurrent()
        defer {
            let duration = CFAbsoluteTimeGetCurrent() - startTime
            logPerformance(operation, duration: duration)
        }
        return try await block()
    }
}

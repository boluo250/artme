//
//  Logger.swift
//  ArtMe
//
//  统一日志工具，支持区分 Debug / Info 等级
//

import Foundation

/// 日志级别
enum LogLevel: String {
    case debug = "DEBUG"
    case info  = "INFO"
    case warn  = "WARN"
    case error = "ERROR"
}

/// 统一日志入口
/// - 使用方式:
///   - `Log.debug("xxx")` 只在 Debug 构建下输出
///   - `Log.info("xxx")` 在 Debug 和 Release 都输出
///   - 根据需要可扩展 warn / error
struct Log {
    
    /// 内部通用打印函数
    private static func log(
        _ level: LogLevel,
        _ message: @autoclosure () -> String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        let fileName = (file as NSString).lastPathComponent
        
        #if DEBUG
        // Debug 构建：所有级别都打印
        print("[\(level.rawValue)] \(fileName)#\(function):\(line) - \(message())")
        #else
        // Release 构建：忽略 debug，只输出 info 及以上
        switch level {
        case .debug:
            return
        default:
            print("[\(level.rawValue)] \(fileName)#\(function):\(line) - \(message())")
        }
        #endif
    }
    
    /// Debug 日志：只在 Debug 构建下输出
    static func debug(
        _ message: @autoclosure () -> String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(.debug, message(), file: file, function: function, line: line)
    }
    
    /// Info 日志：Debug / Release 都输出
    static func info(
        _ message: @autoclosure () -> String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(.info, message(), file: file, function: function, line: line)
    }
    
    /// Warn 日志：保留扩展用
    static func warn(
        _ message: @autoclosure () -> String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(.warn, message(), file: file, function: function, line: line)
    }
    
    /// Error 日志：保留扩展用
    static func error(
        _ message: @autoclosure () -> String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(.error, message(), file: file, function: function, line: line)
    }
}



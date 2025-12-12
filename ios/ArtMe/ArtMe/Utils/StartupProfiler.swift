//
//  StartupProfiler.swift
//  ArtMe
//
//  启动阶段性能统计工具：用于记录 App 启动过程中各模块的耗时
//

import Foundation

/// 启动性能统计工具
/// - 使用方式：
///   - `StartupProfiler.mark("阶段名称")`
///   - 会在控制台输出该阶段距离 App 启动的累计耗时与与上一个阶段的增量耗时
enum StartupProfiler {
    
    /// App 启动时间（第一次访问本枚举时记录）
    private static let appStartTime: Date = {
        let now = Date()
        Log.info("⏱ [Startup] 记录 appStartTime = \(now.timeIntervalSince1970)")
        return now
    }()
    
    /// 上一次打点时间
    private static var lastMarkTime: Date = appStartTime
    
    /// 记录一个阶段的时间点
    /// - Parameter stage: 阶段名称（例如："App 初始化完成"、"首页 View 构建完成"）
    static func mark(_ stage: String) {
        let now = Date()
        let total = now.timeIntervalSince(appStartTime)
        let delta = now.timeIntervalSince(lastMarkTime)
        lastMarkTime = now
        
        let totalStr = String(format: "%.3f", total)
        let deltaStr = String(format: "%.3f", delta)
        
        Log.info("⏱ [Startup] \(stage) | +\(deltaStr)s (累计 \(totalStr)s)")
    }
}



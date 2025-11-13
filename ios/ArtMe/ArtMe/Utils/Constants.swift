//
//  Constants.swift
//  ArtMe
//
//  常量定义
//

import Foundation

struct Constants {
    // API 配置
    #if DEBUG
    static let apiBaseURL = "http://localhost:8000"
    #else
    static let apiBaseURL = "https://api.artme.com"
    #endif
    
    static let apiVersion = "v1"
    
    // API 端点
    struct API {
        static let generate = "/api/\(apiVersion)/generate"
        static let styles = "/api/\(apiVersion)/styles"
        static let models = "/api/\(apiVersion)/models"
        static let account = "/api/\(apiVersion)/account"
        static let subscription = "/api/\(apiVersion)/subscription"
    }
    
    // 网络配置
    static let requestTimeout: TimeInterval = 60.0
    static let imageCacheSize: Int = 100 * 1024 * 1024 // 100MB
}


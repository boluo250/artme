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
    #if targetEnvironment(simulator)
    // 模拟器：使用 localhost 可以访问 Mac 上的服务
    static let apiBaseURL = "http://localhost:8000"
    #else
    // 真机：需要使用 Mac 的局域网 IP 地址
    // 注意：请将下面的 IP 地址替换为你的 Mac 的实际 IP 地址
    // 获取 Mac IP: ipconfig getifaddr en0 或 ifconfig | grep "inet " | grep -v 127.0.0.1
    static let apiBaseURL = "http://192.168.31.128:8000"
    #endif
    #else
    static let apiBaseURL = "https://api.artme.com"
    #endif
    
    static let apiVersion = "v1"
    
    // API 端点
    struct API {
        static let generate = "/api/\(apiVersion)/generate"
        static let generateWithImage = "/api/\(apiVersion)/generate/with-image"
        static let styles = "/api/\(apiVersion)/styles"
        static let prompts = "/api/\(apiVersion)/prompts"
        static let models = "/api/\(apiVersion)/models"
        static let account = "/api/\(apiVersion)/account"
        static let subscription = "/api/\(apiVersion)/subscription"
    }
    
    // 网络配置
    static let requestTimeout: TimeInterval = 60.0
    static let imageCacheSize: Int = 100 * 1024 * 1024 // 100MB
}


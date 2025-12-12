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
    // 真机：使用当前 Mac 的局域网 IP 地址
    // 当前 Mac IP（en0）：192.168.31.147
    // 如果 IP 变化，可在终端用 `ipconfig getifaddr en0` 重新查询并更新此处
    static let apiBaseURL = "http://192.168.31.147:8000"
    #endif
    #else
    // ⚠️ 临时配置：Release 也指向本地/局域网后端，方便排查问题
    // 上架或连接正式环境前，请改回正式 HTTPS 域名
    static let apiBaseURL = "http://192.168.31.147:8000"
    #endif
    
    static let apiVersion = "v1"
    
    // API 端点
    struct API {
        static let generate = "/api/\(apiVersion)/generate"
        static let generateWithImage = "/api/\(apiVersion)/generate/with-image"
        static let tasks = "/api/\(apiVersion)/generate/tasks"
        static let styles = "/api/\(apiVersion)/styles"
        static let prompts = "/api/\(apiVersion)/prompts"
        static let models = "/api/\(apiVersion)/models"
        static let account = "/api/\(apiVersion)/account"
        static let subscription = "/api/\(apiVersion)/subscription"
        static let auth = "/api/\(apiVersion)/auth"
        static let user = "/api/\(apiVersion)/user"
    }
    
    // 网络配置
    static let requestTimeout: TimeInterval = 60.0
    static let imageCacheSize: Int = 100 * 1024 * 1024 // 100MB
}


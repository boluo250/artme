//
//  APIService.swift
//  ArtMe
//
//  API 客户端封装
//

import Foundation
import UIKit

enum APIError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case decodingError(Error)
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "无效的 URL 地址，请检查 API 配置"
        case .invalidResponse:
            return "服务器响应格式无效"
        case .httpError(let statusCode):
            return "服务器错误 (HTTP \(statusCode))"
        case .decodingError(let error):
            return "数据解析失败: \(error.localizedDescription)"
        case .networkError(let error):
            if let urlError = error as? URLError {
                switch urlError.code {
                case .notConnectedToInternet:
                    return "网络连接失败，请检查网络设置"
                case .cannotConnectToHost:
                    var message = "无法连接到服务器，请检查 API 地址配置"
                    // 检查是否是 localhost 连接问题
                    #if targetEnvironment(simulator)
                    message += "\n\n当前 API 地址: \(APIService.shared.baseURL)"
                    #else
                    // 真机运行时，如果使用 localhost，给出提示
                    if APIService.shared.baseURL.contains("localhost") || APIService.shared.baseURL.contains("127.0.0.1") {
                        message += "\n\n检测到使用 localhost 地址，真机无法连接到 Mac。\n请在 Constants.swift 中将 localhost 改为 Mac 的局域网 IP 地址（如 192.168.x.x:8000）"
                    } else {
                        message += "\n\n当前 API 地址: \(APIService.shared.baseURL)"
                        message += "\n请确保后端服务正在运行且地址正确"
                    }
                    #endif
                    return message
                case .timedOut:
                    return "请求超时，请稍后重试"
                case .cannotFindHost:
                    return "找不到服务器，请检查 API 地址配置"
                default:
                    return "网络错误: \(urlError.localizedDescription)"
                }
            }
            return "网络错误: \(error.localizedDescription)"
        }
    }
}

class APIService {
    static let shared = APIService()
    
    let baseURL: String  // 改为公开属性，以便错误处理中访问
    private let session: URLSession
    
    private init() {
        self.baseURL = Constants.apiBaseURL
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = Constants.requestTimeout
        config.timeoutIntervalForResource = Constants.requestTimeout
        self.session = URLSession(configuration: config)
    }
    
    // MARK: - 通用请求方法
    
    func request<T: Decodable>(
        endpoint: String,
        method: String = "GET",
        body: Data? = nil,
        headers: [String: String]? = nil
    ) async throws -> T {
        guard let url = URL(string: baseURL + endpoint) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // 添加自定义头部
        headers?.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        // 添加请求体
        if let body = body {
            request.httpBody = body
        }
        
        do {
            // 打印请求 URL 用于调试
            print("🌐 API Request: \(request.httpMethod ?? "GET") \(url.absoluteString)")
            
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Invalid response type")
                throw APIError.invalidResponse
            }
            
            print("📥 Response: HTTP \(httpResponse.statusCode)")
            
            guard (200...299).contains(httpResponse.statusCode) else {
                print("❌ HTTP Error: \(httpResponse.statusCode)")
                if let responseString = String(data: data, encoding: .utf8) {
                    print("Response body: \(responseString)")
                }
                throw APIError.httpError(httpResponse.statusCode)
            }
            
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            
            do {
                let result = try decoder.decode(T.self, from: data)
                print("✅ Decode success")
                return result
            } catch {
                print("❌ Decode error: \(error)")
                if let responseString = String(data: data, encoding: .utf8) {
                    print("Response body: \(responseString.prefix(500))")
                }
                throw APIError.decodingError(error)
            }
            
        } catch let error as DecodingError {
            print("❌ DecodingError: \(error)")
            throw APIError.decodingError(error)
        } catch let error as APIError {
            print("❌ APIError: \(error)")
            throw error
        } catch let urlError as URLError {
            if urlError.code == .cancelled {
                // 用户触发刷新/页面切换导致的取消，避免误导性错误日志
                print("↩️ Request cancelled")
            } else {
                print("❌ Network error: \(urlError)")
            }
            throw APIError.networkError(urlError)
        } catch {
            print("❌ Network error: \(error)")
            throw APIError.networkError(error)
        }
    }
    
    // MARK: - 图像生成
    
    func generateImage(request: GenerateImageRequest) async throws -> GenerateImageResponse {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let body = try encoder.encode(request)
        
        return try await self.request(
            endpoint: Constants.API.generate,
            method: "POST",
            body: body
        )
    }
    
    // MARK: - 风格管理
    
    func listStyles(category: String? = nil, limit: Int = 20, offset: Int = 0) async throws -> StyleListResponse {
        var endpoint = Constants.API.styles + "/list"
        var queryItems: [String] = []
        
        if let category = category {
            queryItems.append("category=\(category)")
        }
        queryItems.append("limit=\(limit)")
        queryItems.append("offset=\(offset)")
        
        if !queryItems.isEmpty {
            endpoint += "?" + queryItems.joined(separator: "&")
        }
        
        return try await self.request(endpoint: endpoint)
    }
    
    func searchStyles(query: String, limit: Int = 20) async throws -> StyleListResponse {
        let endpoint = Constants.API.styles + "/search?q=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query)&limit=\(limit)"
        return try await self.request(endpoint: endpoint)
    }
    
    func getStyle(styleId: String) async throws -> Style {
        let endpoint = Constants.API.styles + "/\(styleId)"
        return try await self.request(endpoint: endpoint)
    }
    
    // MARK: - 模型列表
    
    func listModels() async throws -> ModelListResponse {
        return try await self.request(endpoint: Constants.API.models)
    }
    
    // MARK: - Prompt 管理
    
    func fetchPromptStyles() async throws -> PromptStyleListResponse {
        let endpoint = Constants.API.prompts + "/list"
        return try await self.request(endpoint: endpoint)
    }
    
    // 获取数据版本号（用于检查是否有更新）
    func fetchPromptStylesVersion() async throws -> PromptStyleVersionResponse {
        let endpoint = Constants.API.prompts + "/version"
        return try await self.request(endpoint: endpoint)
    }
    
    // MARK: - 图片上传生成
    
    func generateImageWithUpload(request: GenerateImageWithUploadRequest) async throws -> GenerateImageWithUploadResponse {
        guard let url = URL(string: baseURL + Constants.API.generateWithImage) else {
            throw APIError.invalidURL
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        
        // 创建 multipart/form-data 请求体
        let boundary = UUID().uuidString
        urlRequest.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // 添加图片数据
        if let imageData = request.image.jpegData(compressionQuality: 0.8) {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"image\"; filename=\"image.jpg\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
            body.append(imageData)
            body.append("\r\n".data(using: .utf8)!)
        }
        
        // 添加 category
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"category\"\r\n\r\n".data(using: .utf8)!)
        body.append(request.category.data(using: .utf8)!)
        body.append("\r\n".data(using: .utf8)!)
        
        // 添加 subcategory
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"subcategory\"\r\n\r\n".data(using: .utf8)!)
        body.append(request.subcategory.data(using: .utf8)!)
        body.append("\r\n".data(using: .utf8)!)
        
        // 添加 userId（如果提供）
        if let userId = request.userId {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"user_id\"\r\n\r\n".data(using: .utf8)!)
            body.append(userId.data(using: .utf8)!)
            body.append("\r\n".data(using: .utf8)!)
        }
        
        // 添加 size
        if let size = request.size {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"size\"\r\n\r\n".data(using: .utf8)!)
            body.append(size.data(using: .utf8)!)
            body.append("\r\n".data(using: .utf8)!)
        }
        
        // 添加 watermark
        if let watermark = request.watermark {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"watermark\"\r\n\r\n".data(using: .utf8)!)
            body.append((watermark ? "true" : "false").data(using: .utf8)!)
            body.append("\r\n".data(using: .utf8)!)
        }
        
        // 添加 max_images
        if let maxImages = request.maxImages {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"max_images\"\r\n\r\n".data(using: .utf8)!)
            body.append(String(maxImages).data(using: .utf8)!)
            body.append("\r\n".data(using: .utf8)!)
        }
        
        // 结束 boundary
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        urlRequest.httpBody = body
        
        do {
            let (data, response) = try await session.data(for: urlRequest)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                throw APIError.httpError(httpResponse.statusCode)
            }
            
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            return try decoder.decode(GenerateImageWithUploadResponse.self, from: data)
            
        } catch let error as DecodingError {
            throw APIError.decodingError(error)
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkError(error)
        }
    }
}

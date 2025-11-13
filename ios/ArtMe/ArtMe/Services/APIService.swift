//
//  APIService.swift
//  ArtMe
//
//  API 客户端封装
//

import Foundation

enum APIError: Error {
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case decodingError(Error)
    case networkError(Error)
}

class APIService {
    static let shared = APIService()
    
    private let baseURL: String
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
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                throw APIError.httpError(httpResponse.statusCode)
            }
            
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            return try decoder.decode(T.self, from: data)
            
        } catch let error as DecodingError {
            throw APIError.decodingError(error)
        } catch let error as APIError {
            throw error
        } catch {
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
}


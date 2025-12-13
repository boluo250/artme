//
//  SessionManager.swift
//  ArtMe
//
//  游客会话管理：用于在屏蔽手机号登录后，仍能拿到可用的 userId
//

import Foundation

@MainActor
enum SessionManager {
    private static let apiService = APIService.shared
    
    static var userId: String? {
        UserDefaults.standard.string(forKey: "userId")
    }
    
    static var phoneNumber: String? {
        UserDefaults.standard.string(forKey: "phoneNumber")
    }
    
    static func saveAuth(userId: String, phoneNumber: String?) {
        UserDefaults.standard.set(userId, forKey: "userId")
        if let phoneNumber {
            UserDefaults.standard.set(phoneNumber, forKey: "phoneNumber")
        } else {
            UserDefaults.standard.removeObject(forKey: "phoneNumber")
        }
    }
    
    /// 若本地没有 userId，则向后端创建游客账号并保存
    static func ensureGuestUser() async throws -> String {
        if let existing = userId, !existing.isEmpty {
            return existing
        }
        
        let auth = try await apiService.createGuestUser()
        saveAuth(userId: auth.userId, phoneNumber: auth.phoneNumber.isEmpty ? nil : auth.phoneNumber)
        return auth.userId
    }
    
    static func logout() {
        UserDefaults.standard.removeObject(forKey: "userId")
        UserDefaults.standard.removeObject(forKey: "phoneNumber")
    }
}



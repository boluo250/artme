//
//  PickerCache.swift
//  ArtMe
//
//  负责缓存并预热一个全局共用的 PHPickerViewController 实例，
//  避免 SwiftUI .sheet 每次重新创建导致预热失效。
//

import Foundation
import PhotosUI

final class PickerCache {
    static let shared = PickerCache()
    
    private(set) var picker: PHPickerViewController?
    
    private init() {}
    
    func prepare() {
        print(">>> [PickerCache] Preparing cached picker...")
        
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        
        let picker = PHPickerViewController(configuration: config)
        _ = picker.view    // 强制加载视图，完成 UI 初始化
        print(">>> [PickerCache] Picker .view loaded")
        
        self.picker = picker
    }
}



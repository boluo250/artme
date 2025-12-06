//
//  PhotoPreheater.swift
//  ArtMe
//
//  相册/Photos 框架预热工具（含完整调试日志）
//

import Foundation
import Photos
import PhotosUI

final class PhotoPreheater {
    static let shared = PhotoPreheater()

    private var started = false
    private let lock = NSLock()

    func preheatIfNeeded() {
        print(">>> [Preheater] preheatIfNeeded CALLED")

        lock.lock()
        if started {
            print(">>> [Preheater] Already started, skip")
            lock.unlock()
            return
        }
        started = true
        lock.unlock()

        print(">>> [Preheater] Start requesting authorization...")

        // Step 1. 请求权限（可能会触发系统第一次 TCC 初始化）
        PHPhotoLibrary.requestAuthorization { status in
            print(">>> [Preheater] Authorization result = \(status.rawValue)")

            guard status == .authorized || status == .limited else {
                print(">>> [Preheater] No permission, stop warm-up")
                return
            }

            // Step 2. PhotoKit 预热（必须在主线程）
            DispatchQueue.main.async {
                print(">>> [Preheater] Start warming PhotoKit daemon...")

                let assets = PHAsset.fetchAssets(with: .image, options: nil)
                print(">>> [Preheater] Asset count = \(assets.count)")

                if assets.count > 0 {
                    assets.enumerateObjects { _, _, stop in
                        print(">>> [Preheater] Access first asset (trigger photolibraryd)")
                        stop.pointee = true
                    }
                } else {
                    print(">>> [Preheater] No images in library, still continue")
                }

                // Step 3. PHPicker 预热（必须访问 .view）
                if #available(iOS 14, *) {
                    print(">>> [Preheater] Start warming PHPickerViewController...")
                    var config = PHPickerConfiguration()
                    config.filter = .images
                    config.selectionLimit = 1

                    let picker = PHPickerViewController(configuration: config)
                    _ = picker.view     // 关键：强制初始化 UI

                    print(">>> [Preheater] Picker view initialized!")
                }

                print(">>> [Preheater] Warm-up completed")
            }
        }
    }
}

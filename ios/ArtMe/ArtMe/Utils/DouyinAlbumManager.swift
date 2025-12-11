import Foundation
import Photos
import UIKit

final class DouyinAlbumManager {
    static let shared = DouyinAlbumManager()

    private(set) var assets: PHFetchResult<PHAsset>?
    private let cachingManager = PHCachingImageManager()
    private var thumbnailSize: CGSize = .zero

    private init() {}

    // 在相册列表的 layout 确定后调用一次，用来设置缩略图大小
    func setThumbnailSize(_ size: CGSize) {
        thumbnailSize = size
    }

    // 请求相册权限 & 拉取所有照片
    func prepareLibrary(completion: @escaping (Bool) -> Void) {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)

        if status == .authorized || status == .limited {
            self.fetchAssets()
            completion(true)
            return
        }

        PHPhotoLibrary.requestAuthorization(for: .readWrite) { newStatus in
            DispatchQueue.main.async {
                if newStatus == .authorized || newStatus == .limited {
                    self.fetchAssets()
                    completion(true)
                } else {
                    completion(false)
                }
            }
        }
    }

    private func fetchAssets() {
        let t0 = CFAbsoluteTimeGetCurrent()

        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        assets = PHAsset.fetchAssets(with: .image, options: options)

        let dt = (CFAbsoluteTimeGetCurrent() - t0) * 1000
        let count = assets?.count ?? 0
        print(">>> [DouyinAlbumManager] fetched \(count) assets in \(String(format: "%.2f", dt)) ms")

        if let assets = assets {
            // 简单预缓存前 200 张缩略图
            let preheatCount = min(200, assets.count)
            var list: [PHAsset] = []
            list.reserveCapacity(preheatCount)
            for i in 0..<preheatCount {
                list.append(assets.object(at: i))
            }
            if thumbnailSize != .zero {
                cachingManager.startCachingImages(
                    for: list,
                    targetSize: thumbnailSize,
                    contentMode: .aspectFill,
                    options: nil
                )
                print(">>> [DouyinAlbumManager] start caching first \(preheatCount) thumbnails")
            }
        }
    }

    func numberOfItems() -> Int {
        return assets?.count ?? 0
    }

    func asset(at indexPath: IndexPath) -> PHAsset? {
        return assets?.object(at: indexPath.item)
    }

    // 请求缩略图（用于九宫格 cell）
    func requestThumbnail(for asset: PHAsset,
                          completion: @escaping (UIImage?) -> Void) {

        let size = thumbnailSize == .zero ? CGSize(width: 150, height: 150) : thumbnailSize

        let options = PHImageRequestOptions()
        options.deliveryMode = .fastFormat
        options.resizeMode = .fast
        options.isSynchronous = false

        cachingManager.requestImage(
            for: asset,
            targetSize: size,
            contentMode: .aspectFill,
            options: options
        ) { image, _ in
            completion(image)
        }
    }

    // 请求大图（用于回调给业务 / 预览）
    func requestFullImage(for asset: PHAsset,
                          maxDimension: CGFloat = 2048,
                          completion: @escaping (UIImage?) -> Void) {

        let targetSize = CGSize(width: maxDimension, height: maxDimension)

        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .fast
        options.isSynchronous = false
        options.isNetworkAccessAllowed = true  // iCloud 照片可下载

        let t0 = CFAbsoluteTimeGetCurrent()

        cachingManager.requestImage(
            for: asset,
            targetSize: targetSize,
            contentMode: .aspectFit,
            options: options
        ) { image, _ in
            let dt = (CFAbsoluteTimeGetCurrent() - t0) * 1000
            print(">>> [DouyinAlbumManager] full image cost \(String(format: "%.2f", dt)) ms")
            completion(image)
        }
    }
}



import SwiftUI
import UIKit

struct DouyinAlbumPickerView: UIViewControllerRepresentable {
    // 选中图片回调
    var onSelected: (UIImage) -> Void

    func makeUIViewController(context: Context) -> UINavigationController {
        let albumVC = DouyinAlbumViewController()
        albumVC.onSelectImage = { image in
            onSelected(image)
        }

        // 包一层导航控制器，顶部显示标题
        let nav = UINavigationController(rootViewController: albumVC)
        return nav
    }

    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {}
}



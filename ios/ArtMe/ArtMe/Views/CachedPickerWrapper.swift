//
//  CachedPickerWrapper.swift
//  ArtMe
//
//  用于让 SwiftUI .sheet 展示已经预热并缓存的 PHPicker 实例，
//  避免每次弹出都重新创建新的 picker。
//

import SwiftUI
import PhotosUI

struct CachedPickerWrapper: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    let onPicked: () -> Void
    
    func makeUIViewController(context: Context) -> UIViewController {
        print(">>> [CachedPickerWrapper] makeUIViewController")
        
        guard let picker = PickerCache.shared.picker else {
            print(">>> [CachedPickerWrapper] ERROR: picker missing")
            return UIViewController()
        }
        
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: CachedPickerWrapper
        
        init(_ parent: CachedPickerWrapper) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            
            guard let provider = results.first?.itemProvider else { return }
            
            provider.loadObject(ofClass: UIImage.self) { image, _ in
                if let uiImage = image as? UIImage {
                    DispatchQueue.main.async {
                        self.parent.selectedImage = uiImage
                        self.parent.onPicked()
                    }
                }
            }
        }
    }
}



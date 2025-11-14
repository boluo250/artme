//
//  PromptStyleDetailView.swift
//  ArtMe
//
//  Prompt 风格详情视图
//

import SwiftUI
import PhotosUI

struct PromptStyleDetailView: View {
    let style: PromptStyle
    
    @State private var image: UIImage?
    @State private var isLoading = true
    @State private var showImagePicker = false
    @State private var showCamera = false
    @State private var selectedImage: UIImage?
    @State private var showGenerateView = false
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 原始大图
                imageView
                    .padding(.horizontal)
                
                // 分类信息
                categoryInfo
                    .padding(.horizontal)
                
                // 操作按钮
                actionButtons
                    .padding(.horizontal)
                    .padding(.bottom)
            }
        }
        .navigationTitle(style.subcategory)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .task {
            await loadImage()
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(selectedImage: $selectedImage, sourceType: .photoLibrary)
        }
        .sheet(isPresented: $showCamera) {
            ImagePicker(selectedImage: $selectedImage, sourceType: .camera)
        }
        .fullScreenCover(isPresented: $showGenerateView) {
            if let selectedImage = selectedImage {
                GenerateViewWithImage(
                    style: style,
                    uploadedImage: selectedImage
                )
            }
        }
    }
    
    private var imageView: some View {
        ZStack {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity)
                    .scaleEffect(scale)
                    .gesture(
                        MagnificationGesture()
                            .onChanged { value in
                                scale = lastScale * value
                            }
                            .onEnded { _ in
                                lastScale = scale
                                // 限制缩放范围
                                if scale < 1.0 {
                                    withAnimation {
                                        scale = 1.0
                                        lastScale = 1.0
                                    }
                                } else if scale > 3.0 {
                                    withAnimation {
                                        scale = 3.0
                                        lastScale = 3.0
                                    }
                                }
                            }
                    )
                    .onTapGesture(count: 2) {
                        // 双击重置缩放
                        withAnimation {
                            scale = 1.0
                            lastScale = 1.0
                        }
                    }
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(maxWidth: .infinity)
                    .frame(height: 400)
                    .overlay {
                        if isLoading {
                            ProgressView()
                        } else {
                            Image(systemName: "photo")
                                .font(.system(size: 50))
                                .foregroundColor(.gray)
                        }
                    }
            }
        }
        .frame(maxWidth: .infinity)
        .cornerRadius(12)
        .shadow(radius: 10)
    }
    
    private var categoryInfo: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("分类信息")
                .font(.headline)
            
            // 分类信息
            HStack {
                Label(style.category, systemImage: "folder")
                    .font(.subheadline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Label(style.subcategory, systemImage: "tag")
                    .font(.subheadline)
                    .foregroundColor(.primary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            // 上传照片按钮
            Button(action: {
                showImagePicker = true
            }) {
                HStack {
                    Image(systemName: "photo.on.rectangle")
                    Text("从相册选择")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            
            // 拍照按钮
            Button(action: {
                showCamera = true
            }) {
                HStack {
                    Image(systemName: "camera")
                    Text("拍照")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            
            // 生成按钮
            Button(action: {
                if selectedImage != nil {
                    showGenerateView = true
                }
            }) {
                HStack {
                    Image(systemName: "sparkles")
                    Text("生成图片")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(selectedImage != nil ? Color.purple : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(selectedImage == nil)
        }
    }
    
    private func loadImage() async {
        isLoading = true
        // 直接使用后端返回的调整后图片URL（已由离线脚本处理）
        let fullURL = Constants.apiBaseURL + style.originalUrl
        do {
            image = try await ImageService.shared.downloadImage(from: fullURL)
        } catch {
            print("加载图片失败: \(error)")
        }
        isLoading = false
    }
}

// MARK: - 图片选择器

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    let sourceType: UIImagePickerController.SourceType
    @Environment(\.dismiss) var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: - 生成视图（带图片）

struct GenerateViewWithImage: View {
    let style: PromptStyle
    let uploadedImage: UIImage
    
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = GenerateViewModel()
    @State private var downloadedImages: [UIImage] = []
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 上传的图片预览
                    Image(uiImage: uploadedImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 300)
                        .cornerRadius(12)
                        .padding()
                    
                    
                    // 生成按钮
                    Button(action: {
                        Task {
                            await generateImage()
                        }
                    }) {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: "sparkles")
                                Text("生成图片")
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(viewModel.isLoading ? Color.gray : Color.purple)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(viewModel.isLoading)
                    .padding(.horizontal)
                    
                    // 错误提示
                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .padding()
                    }
                    
                    // 生成的图片
                    if !viewModel.generatedImages.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("生成的图片")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            ForEach(viewModel.generatedImages) { generatedImage in
                                AsyncImage(url: URL(string: Constants.apiBaseURL + generatedImage.url)) { phase in
                                    switch phase {
                                    case .empty:
                                        ProgressView()
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                    case .failure:
                                        Image(systemName: "photo")
                                            .foregroundColor(.gray)
                                    @unknown default:
                                        EmptyView()
                                    }
                                }
                                .frame(maxHeight: 400)
                                .cornerRadius(12)
                                .padding(.horizontal)
                            }
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("生成图片")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            viewModel.selectedPromptStyle = style
            viewModel.uploadedImage = uploadedImage
        }
    }
    
    private func generateImage() async {
        viewModel.selectedPromptStyle = style
        viewModel.uploadedImage = uploadedImage
        await viewModel.generateImageWithUpload()
    }
}

#Preview {
    PromptStyleDetailView(
        style: PromptStyle(
            id: "test",
            category: "cartoon",
            subcategory: "3D_figurine",
            prompt: "Test prompt",
            thumbnailUrl: "/api/v1/data/cartoon/3D_figurine.jpg",
            originalUrl: "/api/v1/data/cartoon/3D_figurine.jpg"
        )
    )
}


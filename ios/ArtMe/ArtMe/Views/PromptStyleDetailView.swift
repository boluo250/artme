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
    @State private var showImageSourceActionSheet = false
    @State private var selectedImage: UIImage?
    @State private var navigateToGeneration = false
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 原始大图
                imageView
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
            ImagePicker(selectedImage: $selectedImage, sourceType: .photoLibrary) {
                // 选择图片后自动跳转
                navigateToGeneration = true
            }
        }
        .sheet(isPresented: $showCamera) {
            ImagePicker(selectedImage: $selectedImage, sourceType: .camera) {
                // 拍照后自动跳转
                navigateToGeneration = true
            }
        }
        .confirmationDialog("选择图片来源", isPresented: $showImageSourceActionSheet, titleVisibility: .visible) {
            Button("从相册选择") {
                showImagePicker = true
            }
            Button("拍照") {
                showCamera = true
            }
            Button("取消", role: .cancel) {}
        }
        .background(
            Group {
                if let selectedImage = selectedImage {
                    NavigationLink(
                        destination: ImageGenerationView(style: style, uploadedImage: selectedImage),
                        isActive: $navigateToGeneration
                    ) {
                        EmptyView()
                    }
                }
            }
        )
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
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            // 立即制作按钮
            Button(action: {
                showImageSourceActionSheet = true
            }) {
                HStack {
                    Image(systemName: "sparkles")
                    Text("立即制作")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.purple)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
        }
    }
    
    private func loadImage() async {
        isLoading = true
        // 详情页加载原始静态大图（不显示GIF）
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
    let onImageSelected: (() -> Void)?
    @Environment(\.dismiss) var dismiss
    
    init(selectedImage: Binding<UIImage?>, sourceType: UIImagePickerController.SourceType, onImageSelected: (() -> Void)? = nil) {
        self._selectedImage = selectedImage
        self.sourceType = sourceType
        self.onImageSelected = onImageSelected
    }
    
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
                parent.dismiss()
                // 延迟调用回调，确保 dismiss 完成
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.parent.onImageSelected?()
                }
            } else {
                parent.dismiss()
            }
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: - 图片生成视图（独立页面）

struct ImageGenerationView: View {
    let style: PromptStyle
    let uploadedImage: UIImage
    
    @StateObject private var viewModel = GenerateViewModel()
    @State private var hasStartedGeneration = false
    @State private var savingImageId: String?
    @State private var showSaveSuccess = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 生成状态提示
                if viewModel.isLoading {
                    VStack(spacing: 12) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .scaleEffect(1.5)
                        Text("正在生成图片，请稍候...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                }
                
                // 错误提示
                if let errorMessage = viewModel.errorMessage {
                    VStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 40))
                            .foregroundColor(.red)
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                }
                
                // 生成的图片
                if !viewModel.generatedImages.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("生成结果")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ForEach(viewModel.generatedImages) { generatedImage in
                            VStack(spacing: 12) {
                                AsyncImage(url: URL(string: Constants.apiBaseURL + generatedImage.url)) { phase in
                                    switch phase {
                                    case .empty:
                                        ProgressView()
                                            .frame(maxHeight: 400)
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                    case .failure:
                                        VStack {
                                            Image(systemName: "photo")
                                                .font(.system(size: 50))
                                                .foregroundColor(.gray)
                                            Text("加载失败")
                                                .foregroundColor(.gray)
                                        }
                                        .frame(maxHeight: 400)
                                    @unknown default:
                                        EmptyView()
                                    }
                                }
                                .frame(maxHeight: 400)
                                .cornerRadius(12)
                                .shadow(radius: 10)
                                
                                // 保存按钮
                                Button(action: {
                                    Task {
                                        await saveImage(generatedImage: generatedImage)
                                    }
                                }) {
                                    HStack {
                                        if savingImageId == generatedImage.id {
                                            ProgressView()
                                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        } else {
                                            Image(systemName: "square.and.arrow.down")
                                            Text("保存")
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.purple)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                                }
                                .disabled(savingImageId == generatedImage.id)
                            }
                            .padding(.horizontal)
                        }
                    }
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("生成图片")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .alert("保存成功", isPresented: $showSaveSuccess) {
            Button("确定", role: .cancel) {}
        } message: {
            Text("图片已保存到相册")
        }
        .onAppear {
            // 页面出现时自动开始生成
            if !hasStartedGeneration {
                hasStartedGeneration = true
                viewModel.selectedPromptStyle = style
                viewModel.uploadedImage = uploadedImage
                Task {
                    await viewModel.generateImageWithUpload()
                }
            }
        }
    }
    
    private func saveImage(generatedImage: GeneratedImage) async {
        savingImageId = generatedImage.id
        
        do {
            let fullURL = Constants.apiBaseURL + generatedImage.url
            let image = try await ImageService.shared.downloadImage(from: fullURL)
            try await ImageService.shared.saveToPhotoLibrary(image)
            
            await MainActor.run {
                savingImageId = nil
                showSaveSuccess = true
            }
        } catch {
            await MainActor.run {
                savingImageId = nil
                viewModel.errorMessage = "保存失败: \(error.localizedDescription)"
            }
        }
    }
}

#Preview {
    PromptStyleDetailView(
        style: PromptStyle(
            id: "test",
            category: "cartoon",
            categoryId: 1,
            subcategory: "3D_figurine",
            subcategoryId: 1,
            prompt: "Test prompt",
            thumbnailUrl: "/api/v1/data/cartoon/3D_figurine.jpg",
            originalUrl: "/api/v1/data/cartoon/3D_figurine.jpg"
        )
    )
}

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
    /// 选中图片后回调，由上层（ContentView）控制导航；在普通场景下可以为 nil
    let onSelectImage: ((PromptStyle, UIImage) -> Void)?
    
    @State private var image: UIImage?
    @State private var isLoading = true
    // 相册选择相关状态（直接进入自定义抖音风相册）
    @State private var showPhotosPicker = false
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
        .navigationTitle(displayTitle)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadImage()
        }
        .sheet(isPresented: $showPhotosPicker) {
            DouyinAlbumPickerView { image in
                // 选中图片后先关闭相册，再通过回调让上层导航到预览页
                showPhotosPicker = false
                onSelectImage?(style, image)
            }
        }
    }
    
    private var displayTitle: String {
        if let localized = style.subcategoryCn, !localized.isEmpty {
            return localized
        }
        return style.subcategory
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
                showPhotosPicker = true
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
            Log.error("加载图片失败: \(error)")
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

// MARK: - UIKit PHPicker 封装（替代 SwiftUI .photosPicker）

struct PhotoPickerUIKit: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    let onPicked: (() -> Void)?
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.selectionLimit = 1
        config.filter = .images
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ vc: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PhotoPickerUIKit
        
        init(_ parent: PhotoPickerUIKit) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            
            guard let provider = results.first?.itemProvider,
                  provider.canLoadObject(ofClass: UIImage.self) else {
                return
            }
            
            provider.loadObject(ofClass: UIImage.self) { image, _ in
                if let uiImage = image as? UIImage {
                    DispatchQueue.main.async {
                        self.parent.image = uiImage
                        self.parent.onPicked?()
                    }
                }
            }
        }
    }
}

// MARK: - 上传确认视图

struct ImageUploadPreviewView: View {
    let style: PromptStyle
    let uploadedImage: UIImage
    /// 确认生成后的回调，由上层控制导航
    let onConfirmGenerate: (() -> Void)?
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Image(uiImage: uploadedImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity)
                    .cornerRadius(16)
                    .shadow(radius: 10)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("🔥 5积分")
                        .font(.title3)
                        .fontWeight(.semibold)
                    Text("请确认上传图片，系统将在扣除积分后开始生成。")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Button(action: {
                    onConfirmGenerate?()
                }) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("确认并生成")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                
                Button(action: {
                    dismiss()
                }) {
                    Text("重新选择图片")
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.secondary, lineWidth: 1)
                        )
                }
                .foregroundColor(.primary)
            }
            .padding()
        }
        .navigationTitle("确认图片")
        .navigationBarTitleDisplayMode(.inline)
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
    /// 是否展示「制作完成后通知我 / 返回」相关选项（延迟 3 秒后出现）
    @State private var showNotifyOptions = false
    /// 返回到上一页（通常回到「立即制作」风格详情页），由上层控制导航栈
    let onBackToPrevious: (() -> Void)?
    /// 回到首页的回调，由上层控制导航栈
    let onReturnHome: (() -> Void)?
    @EnvironmentObject private var taskStatusManager: TaskStatusManager
    
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

                // 制作中提示
                if let status = viewModel.currentStatus,
                   status == "pending" || status == "processing" {
                    VStack(spacing: 16) {
                        // 大号居中主标题
                        Text("图像制作中...")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity, alignment: .center)

                        // 居中说明文案（两行小字）
                        VStack(spacing: 4) {
                            Text("大约需要40s,请耐心等待")
                            Text("可在\"首页-我的-作品集\"查看进度")
                        }
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity, alignment: .center)
                        
                        // 「制作完成后通知我」区域：延迟 3 秒后出现
                        if showNotifyOptions {
                            Button(action: {
                                handleNotifyAndReturnHome()
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "bell.badge")
                                    Text("制作完成后通知我，返回首页")
                                }
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
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
        // 默认隐藏系统返回按钮，通过自定义左上按钮控制返回逻辑
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                // 仅在展示生成结果时出现：与右上「返回首页」保持一致的出现时机
                if !viewModel.generatedImages.isEmpty {
                    BackButton {
                        onBackToPrevious?()
                    }
                    .contentShape(Rectangle())
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                // 当生成结果已经展示时，在右上显示「返回首页」按钮，仅负责返回，不再勾选通知
                if !viewModel.generatedImages.isEmpty {
                    Button("返回首页") {
                        onReturnHome?()
                    }
                }
            }
        }
        .alert("保存成功", isPresented: $showSaveSuccess) {
            Button("确定", role: .cancel) {}
        } message: {
            Text("图片已保存到相册")
        }
        .sheet(isPresented: $viewModel.showPaymentSheet) {
            PaymentView()
        }
        .onAppear {
            // 页面出现时自动开始生成，但不自动返回首页
            if !hasStartedGeneration {
                hasStartedGeneration = true
                viewModel.selectedPromptStyle = style
                viewModel.uploadedImage = uploadedImage
                
                Task {
                    await viewModel.generateImageWithUpload()
                    // 生成任务创建后，启动全局轮询（如果尚未启动），
                    // 由 TaskStatusManager 统一负责后续状态更新与完成 Toast。
                    taskStatusManager.startPollingIfNeeded()
                }
                
                // 点击「确认并生成」后，延迟 3 秒再展示「制作完成后通知我 / 返回」相关入口
                Task {
                    try? await Task.sleep(nanoseconds: 3_000_000_000)
                    if Task.isCancelled { return }
                    await MainActor.run {
                        showNotifyOptions = true
                    }
                }
            }
        }
        // 当全局任务管理器检测到有任务完成时，如果该任务正好是当前页面的任务，
        // 则主动拉取最新结果并在本页展示生成完成的图片（即使用户没有勾选「制作完成后通知我」也能生效）。
        .onChange(of: taskStatusManager.completedItem?.id) { completedTaskId in
            guard let completedTaskId = completedTaskId,
                  completedTaskId == viewModel.taskId,
                  viewModel.generatedImages.isEmpty else {
                return
            }
            
            Task {
                await viewModel.refreshResultIfNeeded(for: completedTaskId)
            }
        }
    }
    
    /// 用户选择「制作完成后通知我」或点击左上返回时的统一处理逻辑：
    /// 1. 标记当前任务 notifyOnComplete = true
    /// 2. 更新本地历史记录
    /// 3. 调用 onReturnHome 退出当前页面
    private func handleNotifyAndReturnHome() {
        viewModel.notifyOnComplete = true
        if let taskId = viewModel.taskId {
            HistoryManager().updateNotifyOnComplete(id: taskId, notifyOnComplete: true)
        }
        onReturnHome?()
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
            categoryCn: "卡通动漫",
            subcategory: "3D_figurine",
            subcategoryId: 1,
            subcategoryCn: "3D手办",
            prompt: "Test prompt",
            thumbnailUrl: "/api/v1/data/cartoon/3D_figurine.jpg",
            originalUrl: "/api/v1/data/cartoon/3D_figurine.jpg"
        ),
        onSelectImage: nil
    )
}

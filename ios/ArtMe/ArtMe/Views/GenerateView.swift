//
//  GenerateView.swift
//  ArtMe
//
//  图像生成主视图
//

import SwiftUI

struct GenerateView: View {
    @StateObject private var viewModel = GenerateViewModel()
    @State private var showStyleSelection = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: Spacing.xl) {
                    // 输入区域
                    VStack(alignment: .leading, spacing: Spacing.lg) {
                        Text("描述你的头像")
                            .textStyleHeadline()
                        
                        TextEditor(text: $viewModel.prompt)
                            .themeTextEditor(minHeight: 100)
                        
                        // 风格选择
                        Button(action: {
                            showStyleSelection = true
                        }) {
                            HStack {
                                if let style = viewModel.selectedStyle {
                                    Text(style.name)
                                        .textColorPrimary()
                                } else {
                                    Text("选择风格（可选）")
                                        .textColorSecondary()
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray400)
                            }
                            .padding(Spacing.md)
                            .background(Color.adaptive(light: .gray100, dark: .gray700))
                            .cornerRadiusSM()
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .pagePadding()
                    
                    // 生成按钮
                    Button(action: {
                        Task {
                            await viewModel.generateImage()
                        }
                    }) {
                        Text("生成头像")
                            .loading(viewModel.isLoading)
                    }
                    .primaryButtonStyle()
                    .disabled(viewModel.prompt.isEmpty || viewModel.isLoading)
                    .padding(.horizontal, Spacing.lg)
                    
                    // 错误提示
                    if let errorMessage = viewModel.errorMessage {
                        AlertBanner(type: .error, message: errorMessage)
                            .padding(.horizontal, Spacing.lg)
                    }
                    
                    // 生成的图像
                    if let image = viewModel.generatedImage {
                        VStack(spacing: Spacing.lg) {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .cornerRadiusMD()
                                .cardShadow()
                            
                            // 操作按钮
                            HStack(spacing: Spacing.lg) {
                                Button(action: {
                                    Task {
                                        await viewModel.saveImage()
                                    }
                                }) {
                                    Label("保存", systemImage: "square.and.arrow.down")
                                }
                                .secondaryButtonStyle()
                                
                                ShareLink(item: Image(uiImage: image), preview: SharePreview("生成的头像", image: Image(uiImage: image))) {
                                    Label("分享", systemImage: "square.and.arrow.up")
                                }
                                .secondaryButtonStyle()
                            }
                            .padding(.horizontal, Spacing.lg)
                        }
                        .pagePadding()
                    }
                }
            }
            .navigationTitle("生成头像")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showStyleSelection) {
                StyleSelectionView(selectedStyle: $viewModel.selectedStyle)
            }
        }
    }
}

#Preview {
    GenerateView()
}


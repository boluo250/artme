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
                VStack(spacing: 24) {
                    // 输入区域
                    VStack(alignment: .leading, spacing: 16) {
                        Text("描述你的头像")
                            .font(.headline)
                        
                        TextEditor(text: $viewModel.prompt)
                            .frame(height: 100)
                            .padding(8)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        
                        // 风格选择
                        Button(action: {
                            showStyleSelection = true
                        }) {
                            HStack {
                                if let style = viewModel.selectedStyle {
                                    Text(style.name)
                                        .foregroundColor(.primary)
                                } else {
                                    Text("选择风格（可选）")
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        }
                    }
                    .padding()
                    
                    // 生成按钮
                    Button(action: {
                        Task {
                            await viewModel.generateImage()
                        }
                    }) {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("生成头像")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(viewModel.prompt.isEmpty || viewModel.isLoading ? Color.gray : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(viewModel.prompt.isEmpty || viewModel.isLoading)
                    .padding(.horizontal)
                    
                    // 错误提示
                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .padding()
                    }
                    
                    // 生成的图像
                    if let image = viewModel.generatedImage {
                        VStack(spacing: 16) {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .cornerRadius(12)
                                .shadow(radius: 10)
                            
                            // 操作按钮
                            HStack(spacing: 16) {
                                Button(action: {
                                    Task {
                                        await viewModel.saveImage()
                                    }
                                }) {
                                    Label("保存", systemImage: "square.and.arrow.down")
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.blue)
                                        .foregroundColor(.white)
                                        .cornerRadius(8)
                                }
                                
                                ShareLink(item: Image(uiImage: image), preview: SharePreview("生成的头像", image: Image(uiImage: image))) {
                                    Label("分享", systemImage: "square.and.arrow.up")
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.green)
                                        .foregroundColor(.white)
                                        .cornerRadius(8)
                                }
                            }
                            .padding(.horizontal)
                        }
                        .padding()
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


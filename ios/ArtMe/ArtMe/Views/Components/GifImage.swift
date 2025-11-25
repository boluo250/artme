//
//  GifImage.swift
//  ArtMe
//
//  GIF 图片渲染组件 (基于 UIImageView 原生实现)
//  相比 WKWebView，此方案在列表中性能更好，内存占用更低
//

import SwiftUI
import ImageIO

struct GifImage: UIViewRepresentable {
    private let data: Data
    
    init(data: Data) {
        self.data = data
    }

    func makeUIView(context: Context) -> UIImageView {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        // 关键：设置 hug 优先级，防止在 Stack 中被压缩
        imageView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        imageView.setContentHuggingPriority(.defaultLow, for: .vertical)
        imageView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        imageView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        return imageView
    }

    func updateUIView(_ uiView: UIImageView, context: Context) {
        // 调试日志：打印数据长度
        print("GifImage: 更新视图，数据大小: \(data.count) bytes")
        
        // 检查是否已经是正在播放的状态且数据没变
        // 注意：简单的 hashValue 比较可能不够，这里简化判断
        if uiView.isAnimating {
            return
        }
        
        // 异步解析 GIF 数据，避免阻塞主线程
        DispatchQueue.global(qos: .userInteractive).async {
            // 调试日志：开始解析
            print("GifImage: 开始解析 GIF 数据...")
            
            // 尝试创建 CGImageSource
            guard let source = CGImageSourceCreateWithData(self.data as CFData, nil) else {
                print("GifImage Error: 无法创建 CGImageSource")
                return
            }
            
            let count = CGImageSourceGetCount(source)
            print("GifImage: 帧数 = \(count)")
            
            if count <= 1 {
                 print("GifImage: 帧数不足以播放动画，将显示为静态图")
            }
            
            var images: [UIImage] = []
            var duration: TimeInterval = 0
            
            for i in 0..<count {
                if let cgImage = CGImageSourceCreateImageAtIndex(source, i, nil) {
                    images.append(UIImage(cgImage: cgImage))
                    
                    // 获取每一帧的持续时间
                    let delaySeconds = self.delayForImageAtIndex(i, source: source)
                    duration += delaySeconds
                }
            }
            
            print("GifImage: 解析完成，有效帧数: \(images.count), 总时长: \(duration)")
            
            // 回到主线程更新 UI
            DispatchQueue.main.async {
                if !images.isEmpty {
                    if images.count > 1 {
                        // 设置动画
                        uiView.animationImages = images
                        uiView.animationDuration = duration
                        uiView.animationRepeatCount = 0 // 无限循环
                        uiView.image = images.last // 设置最后一张作为静态图备选
                        uiView.startAnimating()
                        print("GifImage: 开始播放动画")
                    } else {
                         // 单帧 GIF，直接显示
                         uiView.image = images.first
                         print("GifImage: 显示单帧静态图")
                    }
                } else {
                    // 如果解析失败，作为普通图片显示
                    print("GifImage Warning: 解析后的图片数组为空，尝试直接加载 Data")
                    uiView.image = UIImage(data: self.data)
                }
            }
        }
    }
    
    // 获取每一帧的延迟时间
    private func delayForImageAtIndex(_ index: Int, source: CGImageSource) -> Double {
        var delay = 0.1
        
        let cfProperties = CGImageSourceCopyPropertiesAtIndex(source, index, nil)
        let gifProperties: CFDictionary? = unsafeBitCast(
            CFDictionaryGetValue(cfProperties, Unmanaged.passUnretained(kCGImagePropertyGIFDictionary).toOpaque()),
            to: CFDictionary.self
        )
        
        var delayObject: AnyObject = unsafeBitCast(
            CFDictionaryGetValue(gifProperties, Unmanaged.passUnretained(kCGImagePropertyGIFUnclampedDelayTime).toOpaque()),
            to: AnyObject.self
        )
        
        if delayObject.doubleValue == 0 {
            delayObject = unsafeBitCast(
                CFDictionaryGetValue(gifProperties, Unmanaged.passUnretained(kCGImagePropertyGIFDelayTime).toOpaque()),
                to: AnyObject.self
            )
        }
        
        delay = delayObject.doubleValue ?? 0
        
        if delay < 0.011 {
            delay = 0.1
        }
        
        return delay
    }
}

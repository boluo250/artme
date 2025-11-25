# iOS 首页 GIF 缩略图支持 - 实现总结

## 概述

实现了首页展示 `_abbreviated` 后缀的缩略图，自动支持 GIF 动画、PNG 和 JPG 等多种格式。

## 实现方案

### 1. 后端处理

**文件**: `artme/backend/app/api/prompts.py`

#### 两个独立的路由和查找函数

1. **缩略图路由**（首页专用）
   - 路由: `/api/v1/prompts/{category}/{subcategory}/thumbnail`
   - 函数: `find_thumbnail_file()` - **只查找带 `_abbreviated` 后缀的文件**
   - 扩展名优先级:
     ```python
     extensions = [
         ".gif", ".GIF",      # 优先返回 GIF 动画
         ".png", ".PNG",      # 其次是 PNG
         ".jpg", ".jpeg", ".JPG", ".JPEG",  # 最后是 JPG
     ]
     ```

2. **原图路由**（详情页专用）
   - 路由: `/api/v1/prompts/{category}/{subcategory}/image`
   - 函数: `find_image_file()` - **优先查找不带 `_abbreviated` 的原始文件**
   - 扩展名优先级:
     ```python
     extensions = [
         ".jpg", ".jpeg", ".JPG", ".JPEG",  # 优先 JPG（原图常用）
         ".png", ".PNG",      # 其次是 PNG
         ".gif", ".GIF",      # 最后才是 GIF
     ]
     ```

### 2. iOS 首页实现

**文件**: `ArtMe/Views/PromptStyleGridView.swift`

#### 核心逻辑

1. **下载图片数据**
   ```swift
   let data = try await ImageService.shared.downloadImageData(from: fullURL)
   ```

2. **检查文件类型**（通过文件头判断）
   ```swift
   private func isGifData(_ data: Data) -> Bool {
       guard data.count >= 6 else { return false }
       let header = data.prefix(6)
       let gif89a = Data([0x47, 0x49, 0x46, 0x38, 0x39, 0x61]) // "GIF89a"
       let gif87a = Data([0x47, 0x49, 0x46, 0x38, 0x37, 0x61]) // "GIF87a"
       return header == gif89a || header == gif87a
   }
   ```

3. **显示对应类型**
   - 如果是 GIF：使用 `GifImage` 组件播放动画
   - 如果不是 GIF：转换为 `UIImage` 显示静态图片

#### 优势
- ✅ 不依赖文件扩展名，通过实际数据判断
- ✅ 自动适配多种格式（.gif / .png / .jpg）
- ✅ 后端可以灵活更换文件格式，前端无需修改
- ✅ 缓存机制正常工作

### 3. iOS 详情页实现

**文件**: `ArtMe/Views/PromptStyleDetailView.swift`

#### 设计决策
- **不显示 GIF**：详情页只加载并显示静态大图
- **原因**：
  - 详情页需要展示高质量的原图供用户查看细节
  - 支持双指缩放手势，GIF 不适合缩放
  - 简化实现，提升性能

#### 实现
```swift
private func loadImage() async {
    isLoading = true
    let fullURL = Constants.apiBaseURL + style.originalUrl
    do {
        // 直接加载静态图片
        image = try await ImageService.shared.downloadImage(from: fullURL)
    } catch {
        print("加载图片失败: \(error)")
    }
    isLoading = false
}
```

### 4. GIF 渲染组件

**文件**: `ArtMe/Views/Components/GifImage.swift`

使用 `WKWebView` 渲染 GIF 动画：

```swift
struct GifImage: UIViewRepresentable {
    let data: Data
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = false
        webView.isUserInteractionEnabled = false
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        uiView.load(
            data,
            mimeType: "image/gif",
            characterEncodingName: "UTF-8",
            baseURL: URL(fileURLWithPath: "")
        )
    }
}
```

## 文件结构示例

后端 `data` 目录结构：
```
artme/backend/data/
├── figure/
│   ├── 3D_figurine.jpg              # 原图
│   ├── 3D_figurine_abbreviated.jpg  # 缩略图（静态）
│   ├── chibi_style.jpg              # 原图
│   ├── chibi_style_abbreviated.gif  # 缩略图（GIF动画）
│   └── chibi_style_abbreviated.png  # 缩略图备选（静态）
└── cartoon/
    ├── dreamy_watercolor.jpg
    └── dreamy_watercolor_abbreviated.png
```

## API 流程

1. **iOS 请求首页数据**
   ```
   GET /api/v1/prompts/list
   ```

2. **后端返回**
   ```json
   {
     "prompts": [
       {
         "id": "figure_chibi_style",
         "category": "figure",
         "subcategory": "chibi_style",
         "thumbnail_url": "/api/v1/prompts/figure/chibi_style/thumbnail",
         "original_url": "/api/v1/prompts/figure/chibi_style/image"
       }
     ]
   }
   ```

3. **iOS 加载首页缩略图**
   ```
   GET /api/v1/prompts/figure/chibi_style/thumbnail
   ```

4. **后端查找缩略图（只查找 _abbreviated 后缀）**
   - 按优先级查找: `chibi_style_abbreviated.gif` → `chibi_style_abbreviated.png` → `chibi_style_abbreviated.jpg`
   - 找到 `chibi_style_abbreviated.gif`，返回 GIF 数据

5. **iOS 渲染首页**
   - 检测到 GIF 文件头
   - 使用 `GifImage` 组件播放动画

6. **iOS 加载详情页原图**
   ```
   GET /api/v1/prompts/figure/chibi_style/image
   ```

7. **后端查找原图（优先查找不带 _abbreviated）**
   - 按优先级查找: `chibi_style.jpg` → `chibi_style.png` → `chibi_style_abbreviated.jpg` (后备)
   - 找到 `chibi_style.jpg`，返回静态大图

8. **iOS 渲染详情页**
   - 显示高质量静态大图
   - 支持双指缩放

## 添加新的缩略图

### 方法 1：使用 GIF 动画

1. 创建 GIF 文件: `{subcategory}_abbreviated.gif`
2. 放置到对应的 category 目录
3. 重启后端服务

### 方法 2：使用静态图片

1. 创建缩略图: `{subcategory}_abbreviated.png` 或 `.jpg`
2. 放置到对应的 category 目录
3. 重启后端服务

### 示例

为 `3D_cartoon_keychain` 添加 GIF 缩略图：

```bash
# 1. 创建 GIF 文件
cp source.gif artme/backend/data/cartoon/3D_cartoon_keychain_abbreviated.gif

# 2. 重启后端
cd artme/backend
python -m uvicorn app.main:app --reload
```

iOS 应用会自动识别并播放 GIF 动画，无需修改任何代码。

## 性能优化

### 缓存策略
- 所有图片数据都会缓存到本地
- 使用 `ImageService` 的内存缓存和文件缓存
- 版本控制机制确保数据及时更新

### 懒加载
- 卡片只在进入屏幕时才加载图片
- 使用 `.task` 修饰符实现异步加载

### 内存管理
- `NSCache` 自动管理内存缓存
- 不可见的图片会自动释放

## 测试建议

### 测试场景

1. **首页 GIF 显示**
   - 验证 GIF 动画正常播放
   - 检查加载速度

2. **首页静态图显示**
   - 验证 PNG/JPG 正常显示
   - 确认布局正确

3. **详情页静态图**
   - 验证大图正常加载
   - 测试缩放手势功能

4. **混合格式**
   - 同一页面显示多种格式（GIF + PNG + JPG）
   - 验证所有格式都能正确渲染

5. **缓存机制**
   - 第一次加载后关闭应用
   - 重新打开，验证从缓存加载

## 技术栈

- **iOS**: SwiftUI + WebKit
- **后端**: FastAPI + Python
- **图片格式**: GIF, PNG, JPEG

## 依赖

- `WebKit` 框架（用于 GIF 渲染）
- `ImageService`（图片下载和缓存）
- `APIService`（网络请求）

## 更新日期

2025-11-26

## 相关文件

- `ArtMe/Views/PromptStyleGridView.swift` - 首页实现
- `ArtMe/Views/PromptStyleDetailView.swift` - 详情页实现
- `ArtMe/Views/Components/GifImage.swift` - GIF 组件
- `artme/backend/app/api/prompts.py` - 后端 API

## 注意事项

1. **GIF 文件大小**：建议 GIF 文件不超过 10MB，避免影响性能
2. **命名规范**：必须使用 `_abbreviated` 后缀
3. **扩展名优先级**：后端会优先返回 .gif 文件
4. **详情页行为**：详情页始终显示静态图，即使缩略图是 GIF

